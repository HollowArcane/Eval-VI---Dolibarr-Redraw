import model/common_model.{Id}
import gleam/int
import gleam/list
import decodex/numbers
import gleam/dynamic/decode

pub type Country
{
    Country(
        id: common_model.Id(Country),
        label: String,
    )
}

pub fn decoder() -> decode.Decoder(Country)
{
    use id <- decode.field("id", numbers.int_decoder() |> decode.map(Id))
    use label <- decode.field("label", decode.string)
    decode.success(Country(id:, label:))
}

pub fn options(data: List(Country))
{
    use country <- list.map(data)
    #(country.id.value |> int.to_string, country.label)
}