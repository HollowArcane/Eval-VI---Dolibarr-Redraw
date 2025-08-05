import gleam/json
import gleam/dynamic/decode

pub type Token
{ Token(value: String) }

pub fn to_json(token: Token) -> json.Json
{
    let Token(value:) = token
    json.object([
        #("value", json.string(value)),
    ])
}

pub fn decoder() -> decode.Decoder(Token)
{
    use value <- decode.field("value", decode.string)
    decode.success(Token(value:))
}