import gleam/result
import util/errors
import given
import gleam/dynamic/decode
import gleam/dict
import redraw/dom/attribute
import util/events
import view/components/bs5
import view/components/stock_asap
import view/components/common
import web/hooks
import model/dolibarr/product/product_model
import service/csrf_token_service
import gleam/javascript/promise
import service/dolibarr/product/product_service
import view/components/generic
import view/templates/template
import redraw/dom/html
import redraw

pub fn create_page()
{
    use <- redraw.component__("ProductPage")

    let #(products, set_products) = redraw.use_state([])
    let #(open, set_open) = redraw.use_state(False)
    let #(#(message_type, message), set_message) = redraw.use_state(#(bs5.secondary, ""))
    let reset_message = fn() {set_message(#(bs5.secondary, ""))}

    let #(loading, set_loading) = redraw.use_state(False)
    let #(errors, set_errors) = redraw.use_state(dict.new())
    let get_error = fn(key) {dict.get(errors, key) |> result.unwrap("")}

    let load_data = redraw.use_callback(fn() {
        use token <- csrf_token_service.require
        
        use products <- promise.await(product_service.list(token))
        case products 
        {
            Error(e) -> { echo e Nil }
            Ok(products) -> set_products(products.body)
        } |> promise.resolve
    }, #())

    let submit_form = redraw.use_callback(fn(form) {
        set_loading(True)
        reset_message()

        use token <- csrf_token_service.require
        
        let product = decode.run(form, product_model.form_decoder())
        use product <- given.ok(product, fn(errors) {
            set_errors(errors.from_decode(errors))
            set_loading(False) |> promise.resolve
        })

        use result <- promise.await(token |> product_service.create(product))
        case result
        {
            Error(e) -> { echo e Nil }
            Ok(_) -> {
                load_data()
                set_message(#(bs5.success, "Produit créé avec succès"))
            }
        } |> promise.resolve

        promise.resolve(set_loading(False))
    }, #())

    hooks.use_init_effect(load_data, #())

    template.home("/product", html.div([], [
        stock_asap.modal(
            open:,
            on_close: fn() {set_open(False)},
            title: "Insertion Produit",
            children: [
                html.form([events.on_submit_object(submit_form)], [
                    case message
                    {
                        "" -> redraw.fragment([])
                        _ -> bs5.alert(message_type, [], [html.text(message)])
                    },

                    bs5.text_input("Réference", get_error("ref"), [attribute.name("ref")]),
                    bs5.text_input("Libellé", get_error("label"), [attribute.name("label")]),
                    bs5.textarea("Description", get_error("description"), [attribute.name("description")]),
                    bs5.number_input("Prix", get_error("price"), [attribute.name("price")]),
                    
                    stock_asap.btn_submit("Valider", loading)
                ])
            ]
        ), 
        common.title([
            stock_asap.btn_add(fn() {
                reset_message()
                set_open(True)
            }),
            html.text("Liste des Produits")
        ]),
        case generic.render_table(products, product_model.format_view)
        {
            Ok(table) -> table
            Error(_) -> common.center_p("Aucune donnée trouvée")
        }
    ]))
}