import gleam/dict
import gleam/list
import gleam/string

@external(javascript, "../route_ffi.mjs", "encode")
pub fn encode(uri: String) -> String

@external(javascript, "../route_ffi.mjs", "goTo")
pub fn go_to(location: String) -> Nil

@external(javascript, "../route_ffi.mjs", "get")
fn do_get() -> String

pub fn get()
{
    case do_get() |> string.split("/") |> list.drop(1)
    {
        [""] -> []
        any -> any
    }
}

@external(javascript, "../route_ffi.mjs", "query")
fn do_query() -> String

pub fn query()
{
    let queries = do_query()
        |> string.drop_start(1)
        |> string.split("&")

    {
        use queries, query <- list.fold(queries, [])
        case string.split_once(query, "=")
        {
            Ok(query) -> [query, ..queries]
            Error(_) -> queries
        }
    } |> dict.from_list
}