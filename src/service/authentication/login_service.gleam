import gleam/dynamic/decode
import model/authentication/login_model.{type Login}
import util/dolibarr
import util/api_request.{JsonBody}
import util/token.{type Token}

pub fn login(login: Login)
{
    api_request.just_post(
        dolibarr.api(["login"], []),
        with: JsonBody(login_model.to_json(login)),
        expect: api_request.expect_json(
            decode.at(["success", "token"], decode.string),
            decode.at(["error", "message"], decode.string),
        )
    )
}

/// Just save the cookie and you're good
pub fn login_unsafe(
    token: Token,
    username username: String,
    password password: String,
)
{
    // fetch to login url with post
    api_request.just_post(
        dolibarr.login,
        with: api_request.Parameters([
            #("token", token.value),
            #("username", username),
            #("password", password),
            #("actionlogin", "login"),
            #("loginfunction", "loginfunction"),
        ]),
        expect: api_request.expect_text()
    )
}