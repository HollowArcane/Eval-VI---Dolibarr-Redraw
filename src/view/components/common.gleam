import gleam/result
import gleam/dict
import util/errors
import given
import gleam/dynamic/decode
import view/components/stock_asap
import util/api_request.{type Error, ApiError}
import gleam/dynamic.{type Dynamic}
import gleam/http/response.{type Response}
import util/token.{type Token}
import gleam/javascript/promise.{type Promise}
import service/csrf_token_service
import redraw.{type Component}
import util/events as custom_events
import view/components/generic
import view/components/fa
import gleam/int
import redraw/dom/events
import view/components/bs5
import redraw/dom/attribute
import redraw/dom/html

pub fn title(content)
{ html.h1([attribute.class_name("d-flex align-items-center gap-3 mb-3")], content) }

pub fn subtitle(content)
{ html.h2([], [html.text(content)]) }

pub fn center_p(text)
{ html.p([attribute.attribute("align", "center")], [html.text(text)]) }

pub fn pagination(page, set_page)
{
    html.div([attribute.class("ms-auto")], [
        bs5.pagination([
            bs5.page_item(False, [
                events.on_click(fn(_) {set_page(int.max(page - 1, 1))})
            ], [fa.icon("fa fa-chevron-left")]),
            bs5.page_item(True, [
                events.on_click(fn(_) {set_page(int.max(page - 1, 1))})
            ], [html.text(int.to_string(page))]),
            bs5.page_item(False, [
                events.on_click(fn(_) {set_page(page + 1)})
            ], [fa.icon("fa fa-chevron-right")]),
        ])
    ])
}

pub fn table(
    format,
    service: fn(Token, Int) -> Promise(Result(Response(List(a)), Error(Dynamic)))
)
{
    let #(data, set_data) = redraw.use_state([])
    let load_data = redraw.use_callback(fn(page) {
        use token <- csrf_token_service.require
        
        use response <- promise.await(service(token, page))
        case response 
        {
            Error(e) -> { echo e Nil }
            Ok(response) -> set_data(response.body)
        } |> promise.resolve
    }, #())

    let component = case generic.render_table(data, format)
    {
        Ok(table) -> table
        Error(_) -> center_p("Aucune donnée trouvée")
    }
    #(component, data, load_data)
}

pub fn modal_form(title title, decoder model_decoder, service service, then then, content content: fn(fn(String) -> String) -> List(Component))
{
    let #(open, set_open) = redraw.use_state(False)
    let #(loading, set_loading) = redraw.use_state(False)
    
    let #(#(message_type, message), set_message) = redraw.use_state(#(bs5.secondary, ""))
    let reset_message = redraw.use_callback(fn() {set_message(#(bs5.secondary, ""))}, #(set_message))
    
    let #(errors, set_errors) = redraw.use_state(dict.new())
    let get_error = redraw.use_callback(fn(key) {dict.get(errors, key) |> result.unwrap("")}, #(errors))

    let submit_form = redraw.use_callback(fn(form) {
        set_loading(True)
        set_errors(dict.new())
        reset_message()

        use token <- csrf_token_service.require
        
        let data = decode.run(form, model_decoder)
        use data <- given.ok(data, fn(errors) {
            set_errors(errors.from_decode(errors))
            set_loading(False) |> promise.resolve
        })

        use result <- promise.await(token |> service(data))
        case result
        {
            Error(ApiError(message)) ->
                set_message(#(bs5.danger, message))
                
            Error(e) ->
                { echo e Nil }

            Ok(_) -> 
                set_message(#(bs5.success, then()))
        } |> promise.resolve

        promise.resolve(set_loading(False))
    }, #())

    let modal = stock_asap.modal(
        open:,
        on_close: fn() {
            set_errors(dict.new())
            set_message(#(bs5.secondary, ""))
            set_open(False)
        },
        title:,
        children: [
            html.form([custom_events.on_submit_object(submit_form)], [
                case message
                {
                    "" -> redraw.fragment([])
                    _ -> bs5.alert(message_type, [], [html.text(message)])
                },

                redraw.fragment(content(get_error)),
                stock_asap.btn_submit("Valider", loading)
            ])
        ]
    )

    #(modal, set_open)
}