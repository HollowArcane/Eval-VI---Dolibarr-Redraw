import gleam/function
import gleam/http
import given
import gleam/http/response
import gleam/javascript/promise
import gleam/list
import gleam/fetch
import gleam/fetch/form_data
import gleam/http/request
import gleam/json
import gleam/dynamic/decode

pub opaque type Expect(a, b)
{
    Bits(handler: fn(response.Response(fetch.FetchBody)) -> promise.Promise(Result(response.Response(a), fetch.FetchError)))
    Text(handler: fn(response.Response(fetch.FetchBody)) -> promise.Promise(Result(response.Response(a), fetch.FetchError)))
    Json(success: decode.Decoder(a), error: decode.Decoder(b))
}

pub type Body
{
    JsonBody(json.Json)
    FormData(form_data.FormData)
    Parameters(List(#(String, String)))
}

pub type Error(custom_error)
{
    MalformedURIError
    ApiAccessError(fetch.FetchError)
    ApiError(custom_error)
    JsonDecodeError(errors: List(decode.DecodeError))
    Other(custom_error)
}

pub fn expect_json(success_decoder, error_decoder)
{ Json(success_decoder, error_decoder) }

pub fn expect_text()
{ Text(fetch.read_text_body) }

pub fn expect_bits()
{ Bits(fetch.read_bytes_body) }

fn resolve_fetch_error(error: fetch.FetchError)
{
    error
        |> ApiAccessError
        |> Error
        |> promise.resolve
}

pub fn post(
    url: String,
    with body: Body,
    expect expect: Expect(success, error),
    setup setup: fn(request.Request(String)) -> request.Request(b)
)
{ http.Post |> to(url, with: body, expect:, setup:) }

pub fn just_post(
    url: String,
    with body: Body,
    expect expect: Expect(success, error)
)
{ http.Post |> to(url, with: body, expect:, setup: function.identity) }

pub fn get(
    url: String,
    with body: Body,
    expect expect: Expect(success, error),
    setup setup: fn(request.Request(String)) -> request.Request(b)
)
{ http.Get |> to(url, with: body, expect:, setup:) }

pub fn just_get(
    url: String,
    with body: Body,
    expect expect: Expect(success, error)
)
{ http.Get |> to(url, with: body, expect:, setup: function.identity) }

pub fn put(
    url: String,
    with body: Body,
    expect expect: Expect(success, error),
    setup setup: fn(request.Request(String)) -> request.Request(b)
)
{ http.Put |> to(url, with: body, expect:, setup:) }

pub fn just_put(
    url: String,
    with body: Body,
    expect expect: Expect(success, error)
)
{ http.Put |> to(url, with: body, expect:, setup: function.identity) }

pub fn patch(
    url: String,
    with body: Body,
    expect expect: Expect(success, error),
    setup setup: fn(request.Request(String)) -> request.Request(b)
)
{ http.Patch |> to(url, with: body, expect:, setup:) }

pub fn just_patch(
    url: String,
    with body: Body,
    expect expect: Expect(success, error)
)
{ http.Patch |> to(url, with: body, expect:,  setup: function.identity) }

pub fn delete(
    url: String,
    with body: Body,
    expect expect: Expect(success, error),
    setup setup: fn(request.Request(String)) -> request.Request(b)
)
{ http.Delete |> to(url, with: body, expect:, setup:) }

pub fn just_delete(
    url: String,
    with body: Body,
    expect expect: Expect(success, error)
)
{ http.Delete |> to(url, with: body, expect:,  setup: function.identity) }

fn to(
    method: http.Method,
    url: String,
    with body: Body,
    expect expect: Expect(success, error),
    setup setup: fn(request.Request(String)) -> request.Request(b)
)
{
    let request = {
        use trigger <- promise.new
        case request.to(url)
        {
            Ok(request) -> Ok(setup(request |> request.set_method(method)))
            Error(_) -> Error(MalformedURIError)
        } |> trigger
    }

    use request <- promise.try_await(request)
    let promise = case body
    {
        FormData(formdata) -> request
            |> request.set_body(formdata)
            |> fetch.send_form_data

        JsonBody(json) -> request
            |> request.set_body(json |> json.to_string)
            |> fetch.send

        Parameters(params) -> {
            use form, #(key, value) <- list.fold(params, form_data.new())
            form |> form_data.append(key, value)
        } |> request.set_body(request, _)
            |> fetch.send_form_data
    }

    use response <- promise.await(promise)
    use response <- given.ok(response, else_return: resolve_fetch_error)

    case expect
    {
        Bits(handler) | Text(handler) -> {
            use response <- promise.await(handler(response))
            use response <- given.ok(response, else_return: resolve_fetch_error)
            promise.resolve(Ok(response))
        }

        Json(success_decoder, error_decoder) -> {
            use response <- promise.await(fetch.read_json_body(response))
            use response <- given.ok(response, else_return: resolve_fetch_error)
            
            case
                decode.run(response.body, success_decoder),
                decode.run(response.body, error_decoder)
            {
                Ok(data), _ -> promise.resolve(Ok(response |> response.set_body(data)))
                _, Ok(error) -> promise.resolve(Error(ApiError(error)))
                Error(errors), _ -> promise.resolve(Error(JsonDecodeError(errors)))
            }
        }
    }
}