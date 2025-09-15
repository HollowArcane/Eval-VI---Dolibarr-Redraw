import model/dolibarr/product/stock_filter
import gleam/float
import given
import toolkit_util/lists
import gleam/pair
import gleam/dict
import gleam/list
import gleam/result
import util/csv
import hooks/common_hooks
import redraw/dom/attribute
import util/errors
import view/components/bs5
import service/dolibarr/product/warehouse_service
import util/swal
import gleam/javascript/promise
import service/dolibarr/product/product_service
import service/csrf_token_service
import model/dolibarr/product/warehouse_model
import model/dolibarr/product/product_model
import gleam/dynamic/decode.{DecodeError}
import util/common_utils
import model/dolibarr/product/stock_model.{type Stock}
import service/dolibarr/product/stock_service
import gleam/int
import view/page/page
import redraw

fn fetch_products(set_products)
{
    use token <- csrf_token_service.require
    use products <- promise.await(product_service.fetch_all(token))
    case products 
    {
        Error(_) -> swal.error("Erreur", "Erreur lors de la récupération des produits")
        Ok(#(products, _)) -> set_products(products)
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

pub fn handle_csv(dynamic, products, warehouses)
{
	let keyed_products = products |> product_model.keyed
	let keyed_warehouses = warehouses |> warehouse_model.keyed
	use stocks <- result.try(
		csv.decode_file(dynamic, stock_model.csv_decoder(products, warehouses))
	)
	let stocks = stocks |> list.sort(fn(s1, s2) {
		stock_model.compare_action(s1.action, s2.action)
	})
	use _, errors <- given.all_ok(stocks
		|> list.group(fn(stock) {#( stock.id_product, stock.id_warehouse )})
		|> dict.to_list
		|> list.map(pair.map_second(_, lists.sum(_, fn(stock: Stock) {stock.quantity})))
		|> list.map(fn(pair) {
			case pair.1 >=. 0.
			{
				True -> Ok(Nil)
				False -> Error(pair)
			}
		}), return: fn(_) { Ok(stocks) }
	)
	{
		use #(#(id_product, id_warehouse), quantity) <- list.map(errors)
		DecodeError("Sum of quantities should be positive for product " <> {
			dict.get(keyed_products, id_product)
				|> result.map(fn(product) {
					product.label <> " REF(" <>  product.ref <> ")"
				}) |> result.unwrap("") <> " at warehouse " <>

			dict.get(keyed_warehouses, id_warehouse)
				|> result.map(fn(warehouse) {
					warehouse.location <> " REF(" <>  warehouse.ref <> ")"
				}) |> result.unwrap("")
		} <> ". Computed: " <> float.to_string(quantity), "", [int.to_string(id_product.value) <> ":" <> int.to_string(id_warehouse.value)])
	} |> Error
}

pub fn create_page()
{
    use <- redraw.component__("StockPage")

    let #(products, set_products) = redraw.use_state([])
    let products_dict = redraw.use_memo(fn() {
        products |> product_model.keyed
    }, #(products))

    let #(warehouses, set_warehouses) = redraw.use_state([])
    let warehouses_dict = redraw.use_memo(fn() {
        warehouses |> warehouse_model.keyed
    }, #(warehouses))

    common_hooks.use_init(fn() {fetch_products(set_products)}, #())
    common_hooks.use_init(fn() {fetch_warehouses(set_warehouses)}, #())

    page.create_crud_plus(
        id: "stock",
        title: "Mouvement de Stock",
        get_ref: fn(stock: Stock) {int.to_string(stock.id.value)},
        create_service: stock_service.create,
        read_service: stock_service.fetch,
        update_service: fn(_, _, _) { promise.resolve(Ok(Nil)) },
        delete_service: fn(_, _) {common_utils.promise(fn() {Ok("")})},
        import_service: stock_service.import_,
        default_filter: stock_filter.new(),
        form_decoder: fn() {stock_model.form_decoder(products, warehouses)},
        csv_handler: handle_csv(_, products, warehouses),
        filter_decoder: fn() {decode.success(stock_filter.new())},
        view_format: stock_model.format_view(_, products_dict, warehouses_dict),
        pdf_list_format: stock_model.format_view(_, products_dict, warehouses_dict),
        pdf_card_format: stock_model.format_view(_, products_dict, warehouses_dict),
        csv_format: stock_model.format_csv,
        json_format: stock_model.to_json,
        render_create: render_create(_, products, warehouses),
        render_search: fn(_) {[redraw.fragment([])]})
}

fn render_create(errors, products, warehouses)
{[
    bs5.select(product_model.options(products), "Produit", errors |> errors.get("id_product"), [
        attribute.name("id_product")
    ]),
    bs5.select(warehouse_model.options(warehouses), "Entrepôt", errors |> errors.get("id_warehouse"), [
        attribute.name("id_warehouse")
    ]),
    bs5.number_input("Quantité", errors |> errors.get("quantity"), [
        attribute.name("quantity")
    ]),
    bs5.number_input("Prix", errors |> errors.get("price"), [
        attribute.name("price")
    ]),
    bs5.text_input("Nº de Série", errors |> errors.get("lot"), [
        attribute.name("lot")
    ]),
    bs5.radio([
        #("0", "Ajout"),
        #("1", "Retrait"),
    ], "Action", errors |> errors.get("action"), [
        attribute.name("action")
    ])
]}
