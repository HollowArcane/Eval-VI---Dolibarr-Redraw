import gleam/dict
import gleam/result
import gleam/dynamic/decode.{DecodeError}
import gleam/list

pub fn from_decode(errors: List(decode.DecodeError))
{
    {
        use DecodeError(expected:, path:, ..) <- list.map(errors)
        #(list.first(path) |> result.unwrap(""), "This field should contain a valid " <> expected)
    } |> dict.from_list
}