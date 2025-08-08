import util/token.{Token}
import util/api_request.{ApiError}
import model/authentication/login_model.{Login}
import service/csrf_token_service
import util/route
import gleam/http/response.{Response}
import gleam/result
import util/events
import service/common_service.{FetchError}
import gleam/javascript/promise
import view/components/stock_asap
import redraw/dom/attribute
import redraw/dom/html
import view/components/bs5
import redraw
import service/authentication/login_service

pub fn create_page()
{
    use <- redraw.component__("LoginPage")

    let #(loading, set_loading) = redraw.use_state(False)
    
    let #(username, set_username) = redraw.use_state("")
    let #(password, set_password) = redraw.use_state("")
    let #(message, set_message) = redraw.use_state("")

    let login = redraw.use_callback(fn(_) {
        set_message("")
        set_loading(True)

        use response <- promise.await({
            // do login
            login_service.login(Login(username:, password:))
                |> promise.map(result.map_error(_, FetchError))
        })
        // handle errors
        case response
        {
            Error(FetchError(ApiError(message))) ->
                set_message(message)

            Error(e) -> {
                echo e
                set_message("Une erreur est survenue, veuillez réessayer ultérieurement")
            }

            Ok(Response(body: token, ..)) -> {
                let assert Ok(_) = csrf_token_service.store(Token(token))
                route.go_to("/product")
            }
        }

        promise.resolve(set_loading(False))
    }, #(username, password))

    html.div([attribute.style([
        #("background-image", "url('/img/bg_dolibarr.jpg')"),   
        #("background-size", "cover"),
        #("background-position", "center"),
    ])], [
        html.div([
            attribute.class_name("mask"),
            attribute.style([
                #("background-color", "rgb(0, 0, 0, 0.6)"),
                #("backdrop-filter", "grayscale(30%)"),
            ])
        ], []),
        bs5.center_screen([
            bs5.card_form([events.on_submit(login)], [
                stock_asap.brand(),

                case message != ""
                {
                    True -> bs5.alert(bs5.danger, [], [html.text(message)])
                    False -> redraw.fragment([])
                },

                bs5.text_input("Nom d'Utilisateur", "", [attribute.value(username), events.on_input(set_username)]),
                bs5.password_input("Mot de Passe", "", [attribute.value(password), events.on_input(set_password)]),
                stock_asap.btn_submit("Valider", loading),

                html.hr([attribute.class_name("mt-5")]),
                html.p([attribute.class_name("text-center")], [
                    html.text("© Copyright 2025 - Ω ")
                ]),
            ])
        ])
    ])
}