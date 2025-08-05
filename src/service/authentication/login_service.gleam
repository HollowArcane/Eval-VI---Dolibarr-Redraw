import util/dolibarr
import util/api_request
import util/token.{type Token}

/// Just save the cookie and you're good
pub fn login(
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