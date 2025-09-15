
import model/dolibarr/product/stock_model
import gleam/option.{Some}
import model/dolibarr/product/stock_filter.{StockFilter}
import service/dolibarr/product/stock_service
import view/components/common
import gleam/int
import given
import model/dolibarr/product/warehouse_model
import hooks/common_hooks
import service/dolibarr/product/warehouse_service
import util/swal
import model/dolibarr/product/product_model
import gleam/javascript/promise
import service/dolibarr/product/product_service
import service/csrf_token_service
import model/common_model.{Id}
import view/page/page
import redraw


fn fetch_stocks(set_stocks, id_product)
{
    use token <- csrf_token_service.require
    use products <- promise.await(stock_service.fetch(token, at: 1, where:  StockFilter(id_product: Some(id_product))))
    case products 
    {
        Error(_) -> swal.error("Erreur", "Erreur lors de la récupération du stock")
        Ok(#(stocks, _)) -> stocks
            |> set_stocks
    } |> promise.resolve
}

fn fetch_warehouses(set_warehouses)
{
    use token <- csrf_token_service.require
    use warehouses <- promise.await(warehouse_service.fetch_all(token))
    case warehouses 
    {
        Error(_) -> swal.error("Erreur", "Erreur lors de la récupération des produits")
        Ok(#(warehouses, _)) -> set_warehouses(warehouses)
    } |> promise.resolve
}


pub type Props
{ Props(id: String) }

pub fn create_page()
{
    use Props(id:) <- redraw.component_("BillOfMaterialsCardPage")
    use id <- given.ok(int.parse(id), fn(_) {common.not_found()})
    let id_product = Id(id)

    let #(stocks, set_stocks) = redraw.use_state([])

    let #(warehouses, set_warehouses) = redraw.use_state([])
    let warehouses_dict = redraw.use_memo(fn() {
        warehouses |> warehouse_model.keyed
    }, #(warehouses))

    common_hooks.use_init(fn() {fetch_warehouses(set_warehouses)}, #())
    common_hooks.use_init(fn() {fetch_stocks(set_stocks, id_product)}, #())

    page.create_card(
        path: "product",
        id: id_product,
        title: "Produit",
        initial_data: product_model.new(),
        read_service: product_service.fetch_one,
        parent_view_format: stock_model.format_view_card(_, stocks),
        child_view_format: stock_model.format_view_simple(_, warehouses_dict),
    )
}
