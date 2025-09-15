import util/filter.{type Filter}
import gleam/int
import gleam/http/request
import gleam/dynamic/decode
import util/token.{type Token}
import util/dolibarr
import util/api_request.{Parameters, JsonBody}

pub fn reset(token: Token)
{
	query(
		token, "
SET FOREIGN_KEY_CHECKS = 0;
UPDATE llx_product_stock SET reel = 0;
TRUNCATE llx_commande;
TRUNCATE llx_commande_fournisseur;
TRUNCATE llx_mrp_production;
TRUNCATE llx_mrp_mo;
TRUNCATE llx_bom_bomline;
TRUNCATE llx_bom_bom;
TRUNCATE llx_stock_mouvement;
TRUNCATE llx_entrepot;
TRUNCATE llx_product;
TRUNCATE llx_product_price;
SET FOREIGN_KEY_CHECKS = 1
"
	)
}

pub fn query(_token: Token, query: String)
{
    api_request.just_post(
        dolibarr.db_api,
        with: Parameters([
            #("query", query),
        ]),
        expect: api_request.expect_json(decode.at(["success"], decode.string), decode.string)
    )
}

pub fn list(token: Token, at path: List(String), expect decoder, page page: Int, where filters: List(Filter))
{ token |> fetch_all(at: path, expect: decoder, take: 10, page:, where: filters) }

pub fn fetch_one(token: Token, at path: List(String), expect decoder)
{
    use request <- api_request.get(
        dolibarr.api(path, []),
        with: Parameters([]),
        expect: api_request.expect_json(
            decoder,
            decode.at(["error"], decode.dynamic)
        )
    )
    request |> request.set_header("DOLAPIKEY", token.value)
}

pub fn fetch_all(token: Token, at path: List(String), expect decoder, take limit: Int, page page: Int, where filters: List(Filter))
{
    use request <- api_request.get(
        dolibarr.api(path, [
            #("limit", int.to_string(limit)),
            #("page", int.to_string(page - 1)),
            #("pagination_data", "true"),
            ..case filters
            {
                [] -> []
                _ -> [#("sqlfilters", filters |> filter.to_query)]
            }
        ]),
        with: Parameters([]),
        expect: api_request.expect_json(
            {
                use data <- decode.then(decode.one_of(
                    decode.list(decoder), [
                    decode.at(["data"], decode.list(decoder))
                ]))
                use page_count <- decode.then(decode.optionally_at(["pagination", "page_count"], 1, decode.int))
                decode.success(#(data, page_count))
            },
            decode.at(["error"], decode.dynamic)
        )
    )
    request |> request.set_header("DOLAPIKEY", token.value)
}

pub fn create(token: Token, at path: List(String), model json)
{
    use request <- api_request.post(
        dolibarr.api(path, []),
        with: JsonBody(json),
        expect: api_request.expect_json(
            decode.int,
            decode.at(["error", "message"], decode.string)
        )
    )
    request |> request.set_header("DOLAPIKEY", token.value)
}

pub fn update(token: Token, at path: List(String), model json, expect decoder)
{
    use request <- api_request.put(
        dolibarr.api(path, []),
        with: JsonBody(json),
        expect: api_request.expect_json(
            decoder,
            decode.at(["error", "message"], decode.string)
        )
    )
    request |> request.set_header("DOLAPIKEY", token.value)
}

pub fn delete(token: Token, at path: List(String))
{
    use request <- api_request.delete(
        dolibarr.api(path, []),
        with: Parameters([]),
        expect: api_request.expect_json(
            decode.at(["success", "message"], decode.string),
            decode.at(["error", "message"], decode.string)
        )
    )
    request |> request.set_header("DOLAPIKEY", token.value)
}
