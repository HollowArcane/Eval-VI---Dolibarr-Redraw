import gleam/string
import toolkit_util/recursions
import gleam/int
import gleam/float

pub type Format
{
    Format(
        digits_per_thousand: Int,
        thousand_separator: String,
        digits_in_decimal: Int,
        decimal_separator: String
    )
}

pub const simple_format2 = Format(3, " ", 2, ".")
pub const simple_format3 = Format(3, " ", 3, ".")

pub fn format(value: Float, format: Format) -> String
{
    let Format(thousand_separator:, decimal_separator:, digits_per_thousand:, digits_in_decimal:) = format
    let assert Ok(exponent) = int.power(10, int.to_float(digits_in_decimal))

    let whole_part = value |> float.truncate
    let decimal_part = 
        float.truncate({value -. int.to_float(whole_part)} *. exponent)
            |> int.to_string
    let decimal_part = {
        use #(length, decimal_part) <- recursions.start(#(string.length(decimal_part), decimal_part))
        case length >= digits_in_decimal
        {
            True -> recursions.End(decimal_part)
            False -> recursions.Continue(#(length + 1, "0" <> decimal_part))
        }
    }

    let whole_part = {
        use #(num, digits, i) <- recursions.start(#(whole_part, [], 1))

        case num == 0, i % digits_per_thousand
        {
            True, _ -> recursions.End(digits)
            False, 0 -> recursions.Continue(#(
                num / 10,
                [thousand_separator, int.to_string(num % 10), ..digits],
                i + 1
            ))
            False, _ -> recursions.Continue(#(
                num / 10,
                [int.to_string(num % 10), ..digits],
                i + 1
            ))
        }
    }
    whole_part |> string.join("") <> decimal_separator <> decimal_part
}

pub fn parse(value: String)
{
    case float.parse(value)
    {
        Ok(value) -> Ok(value)
        Error(_) -> case int.parse(value)
        {  
            Ok(value) -> Ok(int.to_float(value))
            Error(_) -> Error(Nil)
        }
    }
}