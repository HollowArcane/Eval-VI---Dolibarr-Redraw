import gleam/bit_array
import gleam/result
import gleam/dynamic
import gleam/javascript/promise
import gleam/list
import gleam/fetch/form_data.{type FormData}
import redraw/dom/attribute
import redraw/event.{type Event}

@external(javascript, "../events_ffi.mjs", "getValue")
fn get_value(event: Event) -> String

@external(javascript, "../events_ffi.mjs", "getFormData")
fn get_formdata(event: Event) -> FormData

pub fn on_input(handler)
{
    use event: Event <- attribute.attribute("onChange")
    handler(get_value(event))
}

pub fn on_submit_object(handler)
{
    use form <- on_submit
    use fields <- promise.map({
        use key <- list.map(form
            |> form_data.keys
        )
        use bits <- promise.map(
            form |> form_data.get_bits(key)
        )
        #(key, bits)
    } |> promise.await_list)
    {
        use #(key, value) <- list.map(fields)
        #(
            dynamic.string(key),
            list.first(value)
                |> result.try(bit_array.to_string)
                |> result.unwrap("")
                |> dynamic.string
        )
    }   |> dynamic.properties
        |> handler
}

pub fn on_submit(handler)
{
    use event: Event <- attribute.attribute("onSubmit")
    handler(get_formdata(event))
}