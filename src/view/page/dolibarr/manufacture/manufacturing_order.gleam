import util/csv
import model/dolibarr/product/product_model
import gleam/list
import service/dolibarr/product/product_service
import model/dolibarr/manufacture/bill_of_materials_model
import service/dolibarr/manufacture/bills_of_materials_service
import service/dolibarr/manufacture/manufacturing_order_service
import model/dolibarr/manufacture/manufacturing_order_model.{type ManufacturingOrder}
import hooks/common_hooks
import service/dolibarr/product/warehouse_service
import util/swal
import gleam/javascript/promise
import service/csrf_token_service
import model/dolibarr/product/warehouse_model
import redraw/dom/attribute
import util/errors
import view/components/bs5
import gleam/dynamic/decode
import view/page/page
import redraw

fn fetch_products(set_products)
{
    use token <- csrf_token_service.require
    use products <- promise.await(product_service.fetch_all(token))
    case products 
    {
        Error(_) -> swal.error("Erreur", "Erreur lors de la récupération des produits")
        Ok(#(products, _)) -> list.filter(products, product_model.is_manufacturable)
            |> set_products
    } |> promise.resolve
}

fn fetch_bill_of_materials(set_boms)
{
    use token <- csrf_token_service.require
    use products <- promise.await(bills_of_materials_service.fetch_all(token))
    case products 
    {
        Error(_) -> swal.error("Erreur", "Erreur lors de la récupération des produits")
        Ok(#(boms, _)) -> set_boms(boms)
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

pub fn create_page()
{
    use <- redraw.component__("ManufacturingOrderPage")

    
    let #(products, set_products) = redraw.use_state([])
    let products_dict = redraw.use_memo(fn() {products |> product_model.keyed}, #(products))
    common_hooks.use_init(fn() {fetch_products(set_products)}, #())

    let #(bill_of_materials, set_bill_of_materials) = redraw.use_state([])
    common_hooks.use_init(fn() {fetch_bill_of_materials(set_bill_of_materials)}, #())

    let #(warehouses, set_warehouses) = redraw.use_state([])
    let warehouses_dict = redraw.use_memo(fn() {warehouses |> warehouse_model.keyed}, #(warehouses))
    common_hooks.use_init(fn() {fetch_warehouses(set_warehouses)}, #())

    page.create_crud_plus(
        id: "manufacturing-order",
        title: "Ordre de Fabrication",
        get_ref: fn(mo: ManufacturingOrder) {mo.ref},
        create_service: manufacturing_order_service.create,
        read_service: manufacturing_order_service.fetch,
        update_service: manufacturing_order_service.update,
        delete_service: manufacturing_order_service.delete,
        import_service: manufacturing_order_service.import_,
        default_filter: Nil, 
        form_decoder: fn() {manufacturing_order_model.form_decoder(bill_of_materials)},
        csv_handler: csv.decode_file(_, manufacturing_order_model.form_decoder(bill_of_materials)),
        filter_decoder: fn() {decode.success(Nil)},
        view_format: manufacturing_order_model.format_view(_, products_dict, warehouses_dict),
        pdf_list_format: manufacturing_order_model.format_view(_, products_dict, warehouses_dict),
        pdf_card_format: manufacturing_order_model.format_view(_, products_dict, warehouses_dict),
        csv_format: manufacturing_order_model.format_csv,
        json_format: manufacturing_order_model.to_json,
        render_create: render_create(_, bill_of_materials, warehouses),
        render_search: fn(_) {[redraw.fragment([])]})
}

pub fn render_create(errors, boms, _warehouses)
{[
//    bs5.text_input("Réference", errors |> errors.get("ref"), [
//        attribute.name("ref")
//    ]),
//    bs5.text_input("Libellé", errors |> errors.get("label"), [
//        attribute.name("label")
//    ]),
    bs5.number_input("Quantité", errors |> errors.get("quantity"), [
        attribute.name("quantity")
    ]),
    bs5.select(bill_of_materials_model.options(boms), "Fabrication", errors |> errors.get("id_bill_of_materials"), [
        attribute.name("id_bill_of_materials")
    ]),
    // bs5.datetime_input("Date Début", errors |> errors.get("date_start"), [
    //     attribute.step("1"),
    //     attribute.name("date_start")
    // ]),
    // bs5.datetime_input("Date Fin", errors |> errors.get("date_end"), [
    //     attribute.step("1"),
    //     attribute.name("date_end")
    // ]),
]}
