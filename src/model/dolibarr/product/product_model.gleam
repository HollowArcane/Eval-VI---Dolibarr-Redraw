import model/dolibarr/product/warehouse_model.{type Warehouse}
import gleam/list
import gleam/dict
import gleam/int
import model/common_model.{Id, type Id}
import decodex/bools
import decodex/strings
import gleam/string
import gleam/option
import view/components/stock_asap.{HTML, BtnDelete, BtnExportPDF, BtnGoto}
import decodex/numbers
import toolkit_util/data
import gleam/json
import gleam/dynamic/decode

pub type Product
{
    Product(
        id: common_model.Id(Product),
        ref: String,
        label: String,
        description: String,
        price: Float,
        status: Bool,
        status_buy: Bool,
        finished: Bool,
	fk_default_warehouse: Id(Warehouse),
    )
}

pub fn new()
{ Product(Id(0), "", "", "", 0., False, False, False, Id(0)) }

pub fn is_manufacturable(product: Product)
{ product.finished }

pub fn options(products: List(Product))
{
    use product <- list.map(products)
    #(int.to_string(product.id.value), product.label)
}

pub fn keyed(products: List(Product))
{
    {
        use product <- list.map(products)
        #(product.id, product)
    } |> dict.from_list
}

pub fn to_json(product: Product) -> json.Json
{
    let Product(id:, ref:, finished:, label:, description:, price:, status:, status_buy:, fk_default_warehouse:) = product
    json.object([
        #("id", json.int(id.value)),
        #("finished", json.bool(finished)),
        #("ref", json.string(ref)),
        #("label", json.string(label)),
        #("description", json.string(description)),
        #("price", json.float(price)),
        #("status_buy", json.bool(status_buy)),
        #("status", json.bool(status)),
        #("fk_default_warehouse", json.int(fk_default_warehouse.value)),
    ])

}

pub fn decoder() -> decode.Decoder(Product)
{
    use id <- decode.field("id", numbers.int_decoder() |> decode.map(Id))
    use finished <- decode.field("finished", decode.optional(bools.decode_int()) |> decode.map(option.unwrap(_, False)))
    use ref <- decode.field("ref", decode.string)
    use label <- decode.field("label", decode.string)
    use description <- decode.field("description", decode.string)
    use price <- decode.field("price", numbers.decoder())
    use status_buy <- decode.field("status_buy", decode.optional(bools.decode_int()) |> decode.map(option.unwrap(_, False)))
    use status <- decode.field("status", decode.optional(bools.decode_int()) |> decode.map(option.unwrap(_, False)))
    use fk_default_warehouse <- decode.field("fk_default_warehouse", decode.optional(numbers.int_decoder() |> decode.map(Id)) |> decode.map(option.unwrap(_, Id(0))))
    decode.success(Product(id:, ref:, finished:, label:, description:, price:, status:, status_buy:, fk_default_warehouse:))
}

pub fn form_decoder() -> decode.Decoder(Product)
{
    use ref <- decode.field("ref",
        decode.string
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty)
    )
    use label <- decode.field("label",
        decode.string    
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty)
    )
    use description <- decode.field("description",
        decode.string
        |> decode.map(string.trim)
    )
    use status_buy <- decode.optional_field("status_buy",
        False,
        bools.decode_string()
    )
    use status <- decode.optional_field("status",
        False,
        bools.decode_string()
    )
    use finished <- decode.optional_field("finished",
        False,
        bools.decode_string()
    )
    use price <- decode.field("price", numbers.decoder())
	let fk_default_warehouse = Id(0)
    decode.success(Product(id: Id(0), ref:, label:, finished:, description:, status_buy:, status:, price:, fk_default_warehouse:))
}

pub fn csv_decoder() -> decode.Decoder(Product)
{
    use ref <- decode.field("ref",
        decode.string
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty)
    )
    use label <- decode.field("label",
        decode.string    
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty)
    )
    use description <- decode.optional_field("description", "",
        decode.string
        |> decode.map(string.trim)
    )
    use status_buy <- decode.optional_field("status_buy",
        False,
        bools.decode_string()
    )
    use status <- decode.optional_field("status",
        False,
        bools.decode_string()
    )
    use finished <- decode.optional_field("finished",
        False,
        bools.decode_string()
    )
    use price <- decode.field("price", numbers.decoder())
	let fk_default_warehouse = Id(0)
    decode.success(Product(id: Id(0), ref:, label:,finished:, status_buy:, status:, description:, price:, fk_default_warehouse:))
}


pub fn format_view_card(model: Product)
{
    let Product(ref:, label:, description:, price:, status:, status_buy:, ..) = model
    [
        #("", data.Other(BtnExportPDF(model))),
        #("", data.Other(BtnDelete(model))),
        #("Réference", data.String(ref)),
        #("Libellé", data.String(label)),
        #("Description", data.Other(HTML(description))),
        #("Disponible à l'Achat", data.Bool(status_buy)),
        #("Disponible à la Vente", data.Bool(status)),
        #("Prix", data.Float(price)),
    ]
}

pub fn format_view(model: Product)
{
    let Product(ref:, label:, description:, price:, status:, status_buy:, ..) = model
    [
        #("", data.Other(BtnExportPDF(model))),
        #("", data.Other(BtnDelete(model))),
        #("", data.Other(BtnGoto("/product/" <> int.to_string(model.id.value)))),
        #("Réference", data.String(ref)),
        #("Libellé", data.String(label)),
        #("Description", data.Other(HTML(description))),
        #("Disponible à l'Achat", data.Bool(status_buy)),
        #("Disponible à la Vente", data.Bool(status)),
        #("Prix", data.Float(price)),
    ]
}

pub fn format_csv(model: Product)
{
	[
		#("id", model.id.value |> data.Int),
		#("ref", model.ref |> data.String),
		#("label", model.label |> data.String),
        #("status", model.status_buy |> data.Bool),
        #("status_buy", model.status |> data.Bool),
		#("description", model.description |> data.String),
		#("price", model.price |> data.Float),
	]
}

