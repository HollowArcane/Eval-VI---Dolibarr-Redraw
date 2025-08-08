import gleam/option.{None}
import gleam/string
import gleam/dynamic/decode
import gleam/regexp.{type Regexp}
pub type Matched
{
    Matched(value: String, pattern: Regexp)
}

pub fn decode_optional(decoder)
{
    decode.one_of(
        decode.optional(decoder), [{
        use str <- decode.then(decode.string)
        case str |> string.trim
        {
            "" -> decode.success(None)
            _ -> decode.failure(None, "Empty")
        }
    }])
}

pub fn match_decoder(pattern: Regexp)
{
    use value <- decode.then(decode.string)
    case pattern |> regexp.check(value)
    {
        True -> decode.success(Matched(value, pattern))
        False -> decode.failure(Matched(value, pattern), "Pattern:" <> string.inspect(pattern))
    }
}