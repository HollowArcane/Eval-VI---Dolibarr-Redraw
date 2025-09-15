import decodex/strings
import decodex/numbers
import util/filter
import toolkit_util/data
import gleam/dynamic/decode
import gleam/option.{None}

pub type WarehouseFilter
{
    WarehouseFilter(
        ref: option.Option(String),
        location: option.Option(String),
        description: option.Option(String),
        id_country: option.Option(Int),
    )
}

pub fn new()
{ WarehouseFilter(None, None, None, None) }

pub fn decoder() -> decode.Decoder(WarehouseFilter)
{
    use ref <- decode.field("ref", strings.decode_optional(decode.string))
    use location <- decode.field("location", strings.decode_optional(decode.string))
    use description <- decode.field("description", strings.decode_optional(decode.string))
    use id_country <- decode.field("id_country", strings.decode_optional(numbers.int_decoder()))
    decode.success(WarehouseFilter(ref:, description:, location:, id_country:))
}
pub fn format(model: WarehouseFilter)
{
	[
		#("ref", model.ref |> option.map(data.String) |> option.unwrap(data.Other(filter.Empty))),
		#("description", model.description |> option.map(data.String) |> option.unwrap(data.Other(filter.Empty))),
		#("lieu", model.location |> option.map(data.String) |> option.unwrap(data.Other(filter.Empty))),
		#("fk_pays", model.id_country |> option.map(data.Int) |> option.unwrap(data.Other(filter.Empty)))
	]
}
