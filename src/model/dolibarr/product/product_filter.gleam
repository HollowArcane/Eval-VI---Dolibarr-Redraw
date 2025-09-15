import decodex/numbers
import decodex/strings
import gleam/option.{None}
import util/filter.{Empty, FloatMax, FloatMin}
import toolkit_util/data
import gleam/dynamic/decode

pub type ProductFilter
{
    ProductFilter(
        ref: option.Option(String),
        label: option.Option(String),
        description: option.Option(String),
        price_min: option.Option(Float),
        price_max: option.Option(Float),
    )
}

pub fn new()
{ ProductFilter(None, None, None, None, None) }

pub fn decoder() -> decode.Decoder(ProductFilter)
{
    use ref <- decode.field("ref", strings.decode_optional(decode.string))
    use label <- decode.field("label", strings.decode_optional(decode.string))
    use description <- decode.field("description", strings.decode_optional(decode.string))
    use price_min <- decode.field("price_min", strings.decode_optional(numbers.decoder()))
    use price_max <- decode.field("price_max", strings.decode_optional(numbers.decoder()))
    decode.success(ProductFilter(ref:, label:, description:, price_min:, price_max:))
}


pub fn format(model: ProductFilter)
{
	[
		#("ref", model.ref |> option.map(data.String) |> option.unwrap(data.Other(Empty))),
		#("label", model.label |> option.map(data.String) |> option.unwrap(data.Other(Empty))),
		#("description", model.description |> option.map(data.String) |> option.unwrap(data.Other(Empty))),
		#("price", model.price_min |> option.map(fn(v) {data.Other(FloatMin(v))}) |> option.unwrap(data.Other(Empty))),
		#("price", model.price_max |> option.map(fn(v) {data.Other(FloatMax(v))}) |> option.unwrap(data.Other(Empty)))
	]
}
