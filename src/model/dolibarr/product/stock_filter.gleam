
import model/dolibarr/product/product_model.{type Product}
import model/common_model.{type Id, Id}
import decodex/numbers
import decodex/strings
import gleam/option.{None, type Option}
import util/filter.{Empty}
import toolkit_util/data
import gleam/dynamic/decode

pub type StockFilter
{
    StockFilter(
	id_product: Option(Id(Product)),
    )
}

pub fn new()
{ StockFilter(None) }

pub fn decoder() -> decode.Decoder(StockFilter)
{
    use id_product <- decode.field("id_product", strings.decode_optional(numbers.int_decoder() |> decode.map(Id)))
    decode.success(StockFilter(id_product:))
}


pub fn format(model: StockFilter)
{
	[
		#("fk_product", model.id_product |> option.map(fn(v) {data.Int(v.value)}) |> option.unwrap(data.Other(Empty)))
	]
}
