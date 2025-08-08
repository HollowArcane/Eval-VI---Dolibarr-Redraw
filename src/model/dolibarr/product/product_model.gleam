import gleam/option.{None}
import view/components/stock_asap.{HTML}
import decodex/numbers
import toolkit_util/data
import gleam/json
import gleam/dynamic/decode

pub type Product
{
    Product(
        id: Int,
        ref: String,
        label: String,
        description: String,
        price: Float,
        fk_default_warehouse: option.Option(Int),
    )
}

pub fn to_json(product: Product) -> json.Json
{
    let Product(id:, ref:, label:, description:, price:, fk_default_warehouse:) = product
    json.object([
        #("id", json.int(id)),
        #("ref", json.string(ref)),
        #("label", json.string(label)),
        #("description", json.string(description)),
        #("price", json.float(price)),
        #("fk_default_warehouse", json.nullable(fk_default_warehouse, json.int)),
    ])
}

pub fn decoder() -> decode.Decoder(Product)
{
    use id <- decode.field("id", numbers.int_decoder())
    use ref <- decode.field("ref", decode.string)
    use label <- decode.field("label", decode.string)
    use description <- decode.field("description", decode.string)
    use price <- decode.field("price", numbers.decoder())
    use fk_default_warehouse <- decode.field("fk_default_warehouse", decode.optional(numbers.int_decoder()))
    decode.success(Product(id:, ref:, label:, description:, price:, fk_default_warehouse:))
}

pub fn form_decoder() -> decode.Decoder(Product)
{
    use ref <- decode.field("ref", decode.string)
    use label <- decode.field("label", decode.string)
    use description <- decode.field("description", decode.string)
    use price <- decode.field("price", numbers.decoder())
    decode.success(Product(id: 0, ref:, label:, description:, price:, fk_default_warehouse: None))
}

pub fn format_view(model: Product)
{
    let Product(ref:, label:, description:, price:, ..) = model
    [
        #("Réference", data.String(ref)),
        #("Libellé", data.String(label)),
        #("Description", data.Other(HTML(description))),
        #("Prix", data.Float(price)),
    ]
}
