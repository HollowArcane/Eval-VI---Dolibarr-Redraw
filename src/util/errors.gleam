import gleam/string
import gleam/pair
import gleam/dict.{type Dict}
import gleam/result
import gleam/dynamic/decode.{type DecodeError}
import gleam/list

pub fn to_string(error: DecodeError, prefix: String)
{
    case error.expected
    {
        "Non Empty" | "Non Blank" | "Field" -> prefix <> "is required"
        "String" | "Int" | "Float" | "Bool" | "Product Type" -> prefix <> "should contain a valid " <> error.expected
        "ExistIn:" <> _ -> prefix <> "should contain an existing value"
        "YYYY-MM-DD HH:MM:SS" -> prefix <> "should contain a valid Timestamp"
        "YYYY-MM-DD" -> prefix <> "should contain a valid Date"
        "HH:MM:SS:MICROS" | "HH:MM:SS" -> "should contain a valid Time"
        message -> message
    }
}

pub fn all(errors: Dict(String, String))
{ errors |> dict.to_list |> list.sort(fn(a, b) {string.compare(pair.first(a), pair.first(b))}) |> list.map(pair.second) }

pub fn get(errors: Dict(String, String), key: String)
{ errors |> dict.get(key) |> result.unwrap("") }

pub fn from_decode(errors: List(DecodeError))
{
    {
        use error <- list.map(errors)
        let message = error |> to_string("This field ")
        #(list.first(error.path) |> result.unwrap(""), message) |> echo
    } |> dict.from_list
}
