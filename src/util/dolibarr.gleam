import gleam/string
import util/route
import gleam/list

pub fn url(url: List(String))
{
    "http://localhost:81/" <> list.map(url, route.encode)
        |> string.join("/")
}

pub const login = "http://localhost:81/custom/login.php"
pub const db_api = "http://localhost:81/custom/db_api.php"