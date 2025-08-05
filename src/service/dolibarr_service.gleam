import gleam/string
import gleam/list
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

pub fn list(token: Token, table: String, decoder)
{ query(token, "SELECT * FROM " <> table, decode.list(decoder)) }

pub fn create(token: Token, table: String, values)
{
    let #(columns, values) = list.unzip(values)
    query(token, "INSERT INTO " <> table <> "(" <> string.join(columns, ",") <> ") VALUES('" <> string.join(values, "', '") <> "')", decode.list(decode.dynamic))
}