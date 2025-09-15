import util/errors
import gleam/int
import given
import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{DecodeError}
import gleam/list
import gsv
import gleam/result


pub fn decode_file_at(location, content: Dynamic, decoder)
{
    use content <- given.ok(
        decode.run(content, decode.at(location, decode.string)),
        Error
    )

    use csv <- result.try(
        gsv.to_dicts(content, ",")
            |> result.replace_error([DecodeError("CSV", "String", [])])
    )

    let result = list.map(csv, fn(row) {
        dynamic.properties(row |> dict.to_list |> list.map(fn(column) {
            #(dynamic.string(column.0), dynamic.string(column.1))
        })) |> decode.run(decoder)
    })

    use _, _ <- given.any_error(result, fn(result) {list.reverse(result) |> Ok})
    {
        use linearized_errors, decode_result, i <-
            list.index_fold(result, [])

        use decode_errors <- given.error(decode_result, fn(_) {linearized_errors})
        use linearized_errors, error <-
            list.fold(decode_errors, linearized_errors)

        let DecodeError(found:, path:, ..) = error
        let path = list.first(path) |> result.unwrap("")
        [
            DecodeError(found:, path: [int.to_string(i + 1) <> ":" <> path], expected: "Error at line " <> int.to_string(i + 1) <> ": " <>
                error |> errors.to_string("'" <> path <> "' ")),
            ..linearized_errors
        ]
    } |> list.reverse |> Error
}

pub fn decode_file(content: Dynamic, decoder)
{ decode_file_at(["file"], content, decoder) }
