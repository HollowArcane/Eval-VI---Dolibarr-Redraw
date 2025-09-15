import service/dolibarr/manufacture/manufacturing_order_service
import model/dolibarr/manufacture/manufacturing_order_model
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


fn fetch_products(set_products)
{
    use token <- csrf_token_service.require
    use products <- promise.await(product_service.fetch_all(token))
    case products 
    {
        Error(_) -> swal.error("Erreur", "Erreur lors de la récupération des produits")
        Ok(#(products, _)) -> products |> set_products
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

//fn fetch_bill_of_materials(set_boms)
//{
//    use token <- csrf_token_service.require
//    use boms <- promise.await(bills_of_materials_service.fetch_all(token))
//    case boms 
//    {
//        Error(_) -> swal.error("Erreur", "Erreur lors de la récupération des produits")
//        Ok(#(boms, _)) -> set_boms(boms)
//    } |> promise.resolve
//}

pub type Props
{ Props(id: String) }

pub fn create_page()
{
    use Props(id:) <- redraw.component_("ManufacturingOrderCardPage")
    use id <- given.ok(int.parse(id), fn(_) {common.not_found()})
    let id = Id(id)

    let #(products, set_products) = redraw.use_state([])
    let products_dict = redraw.use_memo(fn() {products |> product_model.keyed}, #(products))
    common_hooks.use_init(fn() {fetch_products(set_products)}, #())

    let #(warehouses, set_warehouses) = redraw.use_state([])
    let warehouses_dict = redraw.use_memo(fn() {warehouses |> warehouse_model.keyed}, #(warehouses))
    common_hooks.use_init(fn() {fetch_warehouses(set_warehouses)}, #())


    page.create_card(
        path: "manufacturing-order",
        id:,
        title: "Ordre de Fabrication",
        initial_data: manufacturing_order_model.new(),
        read_service: manufacturing_order_service.fetch_one,
        parent_view_format: manufacturing_order_model.format_card(_, products_dict, warehouses_dict),
        child_view_format: manufacturing_order_model.format_item_view(_, products_dict),
    )
}
