import util/filter.{Empty}
import toolkit_util/data
import decodex/strings
import gleam/dynamic/decode
import gleam/option.{None}

pub type BillOfMaterialsFilter
{
    BillOfMaterialsFilter(
        ref: option.Option(String)
    )
}

pub fn bill_of_material_filter_decoder() -> decode.Decoder(BillOfMaterialsFilter)
{
    use ref <- decode.field("ref", strings.decode_optional(decode.string))
    decode.success(BillOfMaterialsFilter(ref:))
}

pub fn new()
{ BillOfMaterialsFilter(ref: None) }
pub fn format(model: BillOfMaterialsFilter)
{
	[
		#("ref", model.ref |> option.map(data.String) |> option.unwrap(data.Other(Empty)))
	]
}
