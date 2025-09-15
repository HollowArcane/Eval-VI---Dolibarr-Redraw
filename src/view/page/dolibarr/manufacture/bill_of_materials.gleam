
import util/csv
import model/dolibarr/manufacture/bill_of_materials_filter
import redraw/dom/events as redraw_events
import view/components/fx
import gleam/float
import model/common_model.{Id}
import gleam/result
import redraw/dom/html
import gleam/int
import util/events
import gleam/list
import hooks/common_hooks
import service/dolibarr/product/warehouse_service
import util/swal
import gleam/javascript/promise
import service/dolibarr/product/product_service
import service/csrf_token_service
import model/dolibarr/product/warehouse_model
import model/dolibarr/product/product_model
import redraw/dom/attribute
import util/errors
import view/components/bs5
import service/dolibarr/manufacture/bills_of_materials_service
import model/dolibarr/manufacture/bill_of_materials_model.{type BillOfMaterials, Item, type Item}
import view/page/page
import redraw


fn fetch_products(set_products, filter)
{
    use token <- csrf_token_service.require
    use products <- promise.await(product_service.fetch_all(token))
    case products, filter 
    {
        Error(_), _ -> swal.error("Erreur", "Erreur lors de la récupération des produits")
        Ok(#(products, _)), True -> list.filter(products, product_model.is_manufacturable) |> set_products
        Ok(#(products, _)), False -> products |> set_products
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
    use <- redraw.component__("BillOfMaterialsPage")

    let #(items, set_items) = redraw.use_state([])
    let replace_item = common_hooks.use_replace_effect(#(items, set_items))
    let push_item = common_hooks.use_push_effect(#(items, set_items))

    let #(manufacturable_products, set_manufacturable_products) = redraw.use_state([])
    let manufacturable_products_dict = redraw.use_memo(fn() {manufacturable_products |> product_model.keyed}, #(manufacturable_products))
    common_hooks.use_init(fn() {fetch_products(set_manufacturable_products, True)}, #())

    let #(products, set_products) = redraw.use_state([])
    let _products_dict = redraw.use_memo(fn() {products |> product_model.keyed}, #(products))
    common_hooks.use_init(fn() {fetch_products(set_products, False)}, #())

    let #(warehouses, set_warehouses) = redraw.use_state([])
    let warehouses_dict = redraw.use_memo(fn() {warehouses |> warehouse_model.keyed}, #(warehouses))
    common_hooks.use_init(fn() {fetch_warehouses(set_warehouses)}, #())

    page.create_crud_plus(
        id: "bill-of-materials",
        title: "Fabrication",
        get_ref: fn(bom: BillOfMaterials) {bom.ref},
        create_service: bills_of_materials_service.create,
        read_service: bills_of_materials_service.fetch,
        update_service: fn(_, _, _) { promise.resolve(Ok(Nil)) },
        delete_service: bills_of_materials_service.delete,
        import_service: bills_of_materials_service.import_,
        default_filter: bill_of_materials_filter.new(), 
        form_decoder: fn() {bill_of_materials_model.form_decoder(items, manufacturable_products, warehouses)},
        csv_handler: csv.decode_file(_, bill_of_materials_model.form_decoder(items, manufacturable_products, warehouses)),
        filter_decoder: bill_of_materials_filter.bill_of_material_filter_decoder,
        view_format: bill_of_materials_model.format_view(_, manufacturable_products_dict, warehouses_dict),
        pdf_list_format: bill_of_materials_model.format_view(_, manufacturable_products_dict, warehouses_dict),
        pdf_card_format: bill_of_materials_model.format_view(_, manufacturable_products_dict, warehouses_dict),
        csv_format: bill_of_materials_model.format_csv,
        json_format: bill_of_materials_model.to_json,
        render_create: render_create(_, items, replace_item, push_item, manufacturable_products, products, warehouses),
        render_search: render_filter
    )
}

fn render_filter(errors)
{
    [
        bs5.text_input("Réference", errors |> errors.get("ref"), [
            attribute.name("ref")
        ]),
    ]
}

fn render_create(errors, items, replace_item, push_item, manufacturable_products, products, warehouses)
{
    let manufacturable_products = redraw.use_memo(fn() {[
        #("", ""),
        ..product_model.options(manufacturable_products)
    ]}, #(products))
    let products = redraw.use_memo(fn() {[
        #("", ""),
        ..product_model.options(products)
    ]}, #(products))
    [
        bs5.text_input("Réference", errors |> errors.get("ref"), [
            attribute.name("ref")
        ]),
        bs5.text_input("Libellé", errors |> errors.get("label"), [
            attribute.name("label")
        ]),
        bs5.radio([
            #("0", "Fabrication"),
            #("1", "Désassemblage"),
        ], "Type", errors |> errors.get("type"), [
            attribute.name("type")
        ]),
        bs5.text_input("Description", errors |> errors.get("description"), [
            attribute.name("description")
        ]),
        bs5.select(manufacturable_products, "Produit", errors |> errors.get("id_product"), [
            attribute.name("id_product")
        ]),
        bs5.number_input("Quantité", errors |> errors.get("quantity"), [
            attribute.name("quantity")
        ]),
        bs5.select(warehouse_model.options(warehouses), "Entrepôt", errors |> errors.get("id_warehouse"), [
            attribute.name("id_warehouse")
        ]),
        html.div([attribute.class("mt-5")], [
            fx.table(
                ["Produit", "Quantité", "Quantité Fixe", "Stock Fixe", "Efficacité"],
                html.tbody([], [
                    html.tr([], [html.td([
                        attribute.attribute("colspan", "5"),
                    ], [bs5.button(bs5.secondary, [
                        attribute.type_("button"),
                        redraw_events.on_click(fn(_) {push_item(Item(
                            id_product: Id(0),
                            quantity: 0.,
                            quantity_frozen: False,
                            stock_change_disable: False,
                            manufacturing_efficiency: 1.
                        ))})
                    ], [
                        html.text("Ajouter une ligne")
                    ])])]),
                    ..list.map(items, with: render_create_item(_, products, replace_item))
                ])
            )],
        )
    ]
}


fn render_create_item(item: Item, products, replace_item)
{
    let Item(id_product:, quantity:, quantity_frozen:, stock_change_disable:, manufacturing_efficiency:) = item
    html.tr([], [
        html.td([], [
            bs5.select(products, label: "", error: "", attributes: [
                attribute.value(int.to_string(id_product.value)),
                events.on_input(fn(id_product) {
                    let assert Ok(id_product) = int.parse(id_product) |> result.map(Id)
                    replace_item(item, fn(item) {Item(..item, id_product:)})
                })
            ]),
        ]),
        html.td([], [
            bs5.number_input(label: "", error: "", attributes: [
                attribute.value(float.to_string(quantity)),
                events.on_input(fn(quantity) {
                    let assert Ok(quantity) = float.parse(quantity)
                    replace_item(item, fn(item) {Item(..item, quantity:)})
                })
            ]),
        ]),
        html.td([], [
            bs5.checkbox(value: "", label: "", error: "", attributes: [
                attribute.checked(quantity_frozen),
                events.on_input(fn(_) {
                    replace_item(item, fn(item) {Item(..item, quantity_frozen: !quantity_frozen)})
                })
            ]),
        ]),
        html.td([], [
            bs5.checkbox(value: "", label: "", error: "", attributes: [
                attribute.checked(stock_change_disable),
                events.on_input(fn(_) {
                    replace_item(item, fn(item) {Item(..item, stock_change_disable: !stock_change_disable)})
                })
            ]),
        ]),
        html.td([attribute.class("d-flex")], [
            bs5.number_input(label: "", error: "", attributes: [
                attribute.value(float.to_string(manufacturing_efficiency *. 100.)),
                events.on_input(fn(manufacturing_efficiency) {
                    let assert Ok(manufacturing_efficiency) = float.parse(manufacturing_efficiency) |> result.try(float.divide(_, 100.))
                    replace_item(item, fn(item) {Item(..item, manufacturing_efficiency:)})
                })
            ]),
            html.text("%")
        ])
    ])
}
