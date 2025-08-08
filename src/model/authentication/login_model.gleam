import gleam/json

pub type Login
{
    Login(
        username: String,
        password: String,
    )
}

pub fn to_json(login: Login) -> json.Json
{
    let Login(username:, password:) = login
    json.object([
        #("login", json.string(username)),
        #("password", json.string(password)),
    ])
}