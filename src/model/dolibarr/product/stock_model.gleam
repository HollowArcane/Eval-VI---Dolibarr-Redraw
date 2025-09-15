import toolkit_util/lists
import gleam/int
import view/components/stock_asap
import gleam/order
import gleam/float
import gleam/string
import decodex/strings
import decodex/numbers
import gleam/result
import gleam/dict.{type Dict}
import toolkit_util/data
import gleam/list
import decodex/relations
import model/common_model.{Id, type Id}
import model/dolibarr/product/warehouse_model.{type Warehouse}
import model/dolibarr/product/product_model.{type Product, Product}
import gleam/json
import gleam/dynamic/decode
import gleam/option

pub type Action
{
    Insert
    Remove
}

pub fn compare_action(a1: Action, a2: Action)
{
	case a1, a2
	{
		Insert, Insert -> order.Eq
		Insert, Remove -> order.Lt
		Remove, Insert -> order.Gt
		Remove, Remove -> order.Eq
	}
}
fn action_decoder() -> decode.Decoder(Action)
{
    use variant <- decode.then(decode.string)
    case variant {
        "0" -> decode.success(Insert)
        "1" -> decode.success(Remove)
        _ -> decode.failure(Insert, "Action")
    }
}

pub type Stock
{
    Stock(
        id: Id(Stock),
        id_product: common_model.Id(Product),
        id_warehouse: common_model.Id(Warehouse),
        quantity: Float,
        price: option.Option(Float),
        lot: String,
        action: Action,
    )
}

pub fn group_by_product(stocks: List(Stock))
{
	use id_product, stocks <- dict.map_values(
		list.group(stocks, fn(stock) {stock.id_product})
	)
	use #(id_warehouse, stocks) <- list.map(
		list.group(stocks, fn(stock) {stock.id_warehouse})
			|> dict.to_list
	)
	let quantity = lists.sum(stocks, fn(stock) {stock.quantity})
	Stock(
		id: Id(0),
		id_product:,
		id_warehouse:,
		quantity:,
		price: option.Some( 0. ),
		lot: "",
		action: case quantity >=. 0.
		{
			True -> Insert
			False -> Remove
		}
	)
}

pub fn to_json(stock: Stock) -> json.Json
{
    let Stock(id:, id_product:, id_warehouse:, quantity:, price:, lot:, action:) = stock
    json.object([
        #("id", json.int(id.value)),
        #("product_id", json.int(id_product.value)),
        #("warehouse_id", json.int(id_warehouse.value)),
        #("qty", json.float(float.absolute_value(quantity) *. case action
		{
			Insert -> 1.
			Remove -> -1.
		})),
        #("lot", json.string(lot)),
        #("price", case price {
            option.None -> json.null()
            option.Some(value) -> json.float(value)
        }),
    ])
}

pub fn decoder() -> decode.Decoder(Stock)
{
    use id <- decode.field("id", numbers.int_decoder() |> decode.map(Id))
    use id_product <- decode.field("product_id", numbers.int_decoder() |> decode.map(Id))
    use id_warehouse <- decode.field("warehouse_id", numbers.int_decoder() |> decode.map(Id))
    use quantity <- decode.field("qty", numbers.decoder())
    use price <- decode.field("price", decode.optional(numbers.decoder()))
    use lot <- decode.optional_field("lot", "", decode.string)
    let action = case quantity >. 0.
    {
        True -> Insert
        False -> Remove
    }

    decode.success(Stock(id:, id_product:, id_warehouse:, quantity:, price:, lot:, action:))
}

pub fn form_decoder(products: List(Product), warehouses: List(Warehouse)) -> decode.Decoder(Stock)
{
    use id_product <- decode.field("id_product", numbers.int_decoder()
        |> decode.map(Id)
        |> decode.then(relations.exists(list.map(products, fn(product) {product.id}))))
    let id_product = id_product.value

    use id_warehouse <- decode.field("id_warehouse", numbers.int_decoder()
        |> decode.map(Id)
        |> decode.then(relations.exists(list.map(warehouses, fn(warehouse) {warehouse.id}))))
    let id_warehouse = id_warehouse.value

    use quantity <- decode.field("quantity", numbers.decoder())
    use lot <- decode.field("lot", decode.string
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty))

    use action <- decode.field("action", action_decoder())
    let quantity = case action
    {
        Insert -> float.absolute_value(quantity)
        Remove -> -1. *. float.absolute_value(quantity)
    }

    use price <- decode.field("price", strings.decode_optional(numbers.decoder()))
    decode.success(Stock(id: Id(0), id_product:, id_warehouse:, quantity:, price:, lot:, action:))
}


pub fn csv_decoder(products: List(Product), warehouses: List(Warehouse)) -> decode.Decoder(Stock)
{
    use product <- decode.field("ref_product", decode.string
        |> decode.then(relations.map_exists(products, product_model.new(), fn(product) {product.ref})))
    let id_product = product.value.id

    use warehouse <- decode.field("ref_warehouse", decode.string
        |> decode.then(relations.map_exists(warehouses, warehouse_model.new(), fn(warehouse) {warehouse.ref})))
    let id_warehouse = warehouse.value.id

    use quantity <- decode.field("quantity", numbers.decoder())
    use lot <- decode.field("lot", decode.string
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty))


    use action <- decode.field("action", action_decoder())
    let quantity = case action
    {
        Insert -> float.absolute_value(quantity)
        Remove -> -1. *. float.absolute_value(quantity)
    }

    use price <- decode.field("price", strings.decode_optional(numbers.decoder()))
    decode.success(Stock(id: Id(0), id_product:, id_warehouse:, quantity:, price:, lot:, action:))
}

pub fn format_csv(model: Stock)
{
	[
		#("id_product", model.id_product.value |> data.Int),
		#("id_warehouse", model.id_warehouse.value |> data.Int),
		#("quantity", model.quantity |> data.Float),
		#("lot", model.lot |> data.String),
		#("action", case model.action
        {
            Insert -> 0
            Remove -> 1
        } |> data.Int),
		#("price", model.price |> option.map(data.Float) |> option.unwrap(data.Other(Nil)))
	]
}

pub fn format_view_simple(model: Stock, warehouses: Dict(Id(Warehouse), Warehouse))
{
	[
		#("Entrepôt", warehouses |> dict.get(model.id_warehouse) |> result.map(fn(warehouse) {warehouse.location}) |> result.unwrap("") |> data.String),
		#("Action", case model.action
        {
            Insert -> "Ajout"
            Remove -> "Retrait"
        } |> data.String),
		#("Quantité", model.quantity |> float.absolute_value |> data.Float),
		#("Prix", model.price |> option.map(data.Float) |> option.unwrap(data.String(""))),
	]
}

pub fn format_view(model: Stock, products: Dict(Id(Product), Product), warehouses: Dict(Id(Warehouse), Warehouse))
{
	[
		#("Produit", products |> dict.get(model.id_product) |> result.map(fn(product) {product.ref <> " - " <> product.label}) |> result.unwrap("") |> data.String),
		#("Entrepôt", warehouses |> dict.get(model.id_warehouse) |> result.map(fn(warehouse) {warehouse.location}) |> result.unwrap("") |> data.String),
		#("Action", case model.action
        {
            Insert -> "Ajout"
            Remove -> "Retrait"
        } |> data.String),
		#("Quantité", model.quantity |> float.absolute_value |> data.Float),
		#("Prix", model.price |> option.map(data.Float) |> option.unwrap(data.String(""))),
	]
}

pub fn format_view_card(model: Product, stocks: List(Stock))
{
    let Product(ref:, label:, description:, price:, status:, status_buy:, ..) = model
	let stock_init = list.max(stocks, fn(s1, s2) {
		int.compare(s2.id.value, s1.id.value)
	})
		|> result.map(fn(stock) {stock.quantity})
		|> result.unwrap(0.)
	let stock_final = lists.sum(stocks, fn(stock) {stock.quantity})
    [
        #("Réference", data.String(ref)),
        #("Libellé", data.String(label)),
        #("Description", data.Other(stock_asap.HTML(description))),
        #("Disponible à l'Achat", data.Bool(status_buy)),
        #("Disponible à la Vente", data.Bool(status)),
        #("Prix", data.Float(price)),
        #("Stock Initial", data.Float(stock_init)),
        #("Stock Final", data.Float(stock_final)),
    ]
}

