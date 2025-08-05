import decodex/numbers
import view/components/stock_asap
import toolkit_util/data
import gleam/json
import gleam/dynamic/decode

pub type Warehouse
{
    Warehouse(
        rowid: Int,
        description: String,
        location: String,
        fk_country: Int,
    )
}

pub fn to_json(warehouse: Warehouse) -> json.Json
{
    let Warehouse(rowid:, description:, location:, fk_country:) = warehouse
    json.object([
        #("rowid", json.int(rowid)),
        #("description", json.string(description)),
        #("location", json.string(location)),
        #("fk_country", json.int(fk_country)),
    ])
}

pub fn api_decoder() -> decode.Decoder(Warehouse)
{
    use rowid <- decode.field("rowid", numbers.int_decoder())
    use description <- decode.field("description", decode.string)
    use location <- decode.field("lieu", decode.string)
    use fk_country <- decode.field("fk_pays", numbers.int_decoder())
    decode.success(Warehouse(rowid:, description:, location:, fk_country:))
}

pub fn decoder() -> decode.Decoder(Warehouse)
{
    use rowid <- decode.field("rowid", numbers.int_decoder())
    use description <- decode.field("description", decode.string)
    use location <- decode.field("location", decode.string)
    use fk_country <- decode.field("fk_country", numbers.int_decoder())
    decode.success(Warehouse(rowid:, description:, location:, fk_country:))
}

pub fn format_view(model: Warehouse)
{
	[
		#("location", model.location |> data.String),
		#("description", model.description |> stock_asap.HTML |> data.Other),
	]
}
