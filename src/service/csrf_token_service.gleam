import util/route
import given
import toolkit_util/resource
import gleam/string
import util/dolibarr
import util/api_request
import gleam/javascript/promise
import util/token.{type Token, Token}
import util/local_storage
import gleam/json
import gleam/result
import service/common_service

pub fn get_or_fetch()
{
    common_service.get_or_fetch_and_store(
        restore,
        fetch,
        store,
    )
}

pub fn require(then)
{
    given.ok(
        restore(),
        fn(_) {
            route.go_to("/login")
            promise.resolve(Nil)
        },
        then
    )
}

pub fn restore()
{
    use token_str <- result.try(local_storage.get("token")
        |> result.replace_error(json.UnableToDecode([])))

    token_str |> json.parse(token.decoder())
}

fn store(token: Token)
{ local_storage.set("token", token.to_json(token) |> json.to_string) }

fn fetch()
{
    // fetch for login form
    use response <- promise.try_await(api_request.just_post(
        dolibarr.login,
        with: api_request.Parameters([
            #("token", "asfwaagefaswd"),
            #("username", "username"),
            #("password", "password"),
            #("actionlogin", "login"),
            #("loginfunction", "loginfunction"),
        ]),
        expect: api_request.expect_text(),
    ))

    // find input name="token" in response
    let token = response.body
        |> string.crop("name=\"token\"")
    // extract value of input
        |> string.crop("value=\"")
        |> string.drop_start(7)
        |> string.split_once("\"")
    
    use <- resource.lazy_defer(promise.resolve)
    case token
    {
        Error(_) -> Error(api_request.Other("Could not find token in server response"))
        Ok(#(value, _)) -> Ok(Token(value:))
    }
}