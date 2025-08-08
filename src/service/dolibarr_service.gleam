import gleam/int
import gleam/http/request
import gleam/dynamic/decode
import util/token.{type Token}
import util/dolibarr
import util/api_request.{Parameters}

pub fn query(token: Token, query: String, decoder)
{
    let token.Token(value:) = token
    api_request.just_post(
        dolibarr.db_api,
        with: Parameters([
            #("token", value),
            #("query", query),
        ]),
        expect: api_request.expect_json(decoder, decode.string)
    )
}

pub fn list(token: Token, item: String, decoder, page: Int)
{
    use request <- api_request.get(
        dolibarr.api([item], [
            #("limit", "10"),
            #("page", int.to_string(page)),
        ]),
        with: Parameters([]),
        expect: api_request.expect_json(
            decode.list(decoder),
            decode.at(["error"], decode.dynamic)
        )
    )
    request |> request.set_header("DOLAPIKEY", token.value)
}

pub fn create(token: Token, item: String, json)
{
    use request <- api_request.post(
        dolibarr.api([item], []),
        with: api_request.JsonBody(json),
        expect: api_request.expect_json(
            decode.int,
            decode.at(["error", "message"], decode.string)
        )
    )
    request |> request.set_header("DOLAPIKEY", token.value)
}