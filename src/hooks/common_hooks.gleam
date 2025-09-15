import gleam/dynamic
import gleam/result
import gleam/list
import model/dolibarr/manufacture/bill_of_materials_model.{type Item}
import gleam/bool
import util/swal
import given
import util/errors
import gleam/dict
import gleam/javascript/promise
import service/csrf_token_service
import redraw
import util/api_request.{ApiError}

pub type Paginated(model)
{ Paginated(data: List(model), page: Int, page_count: Int) }

pub fn use_fetched_state(service, error_message)
{
	let #(data, set_data) = redraw.use_state([])
	use_init(fn() {
		use token <- csrf_token_service.require
		use response <- promise.await(
			service(token)
		)
		case response
		{
			Error(_) -> swal.error("Erreur", error_message)
			Ok(#(data, _)) -> set_data(data)
		} |> promise.resolve
			
	}, #(service, error_message))
	#(data, set_data)
}

pub fn use_replace_effect(
    in state: #(List(Item), fn(List(Item)) -> Nil),
)
{
    let #(items, set_items) = state
    redraw.use_callback(fn(item, map) {
        {
            use old_item <- list.map(items)
            case old_item == item
            {
                False -> old_item
                True -> map(item)
            }
        } |> set_items
    }, #(items))
}


pub fn use_push_effect(
    in state: #(List(Item), fn(List(Item)) -> Nil),
)
{
    let #(items, set_items) = state
    redraw.use_callback(fn(item) {
        [item, ..items] |> set_items
    }, #(items))
}


pub fn use_init(effect, dependencies)
{
    let #(loaded, set_loaded) = redraw.use_state(False)

    redraw.use_effect(fn() {
        case loaded
        {
            False -> {
                effect()
                set_loaded(True)
            }
            True -> Nil
        }
    }, dependencies)
}

pub fn use_update(effect, dependencies)
{
    let #(loaded, set_loaded) = redraw.use_state(False)

    redraw.use_effect(fn() {
        case loaded
        {
            False -> set_loaded(True)
            True -> effect()
        }
    }, dependencies)
}

fn handle_service(service, on_error, on_success)
{
	use token <- csrf_token_service.require
	use result <- promise.await(service(token))
        case result {
            Error(ApiError(message)) -> on_error(message)
            Ok(body) -> on_success(body)

            Error(e) -> {
                echo e
                on_error("Une erreur est survenue. Veuillez réessayer ultérireurement")
            }
        }
        |> promise.resolve
}

pub fn use_form_callback(
    on_submit on_submit,
    on_valid on_valid,
    on_success on_success,
    on_error on_error,
)
{
    let #(submitting, set_submitting) = redraw.use_state(False)
    let #(errors, set_errors) = redraw.use_state(dict.new())

    let on_submit = redraw.use_callback(fn(form) {
        set_submitting(True)
        set_errors(dict.new())

        use token <- csrf_token_service.require

        let data = on_submit(form)
        use data <- given.ok(data, fn(errors) {
          set_errors(errors.from_decode(errors))
          set_submitting(False) |> promise.resolve
        })

        use result <- promise.await(token |> on_valid(data))
        case result {
            Error(ApiError(message)) -> on_error(message)
            Ok(body) -> on_success(body)

            Error(e) -> {
                echo e
                on_error("Une erreur est survenue. Veuillez réessayer ultérireurement")
            }
        }
        |> promise.resolve

        promise.resolve(set_submitting(False))
      },
      #(on_submit, on_valid, on_success, on_error),
    )
    let reset_errors = redraw.use_callback(fn() {
        set_errors(dict.new())
    }, #())

    #(submitting, on_submit, errors, reset_errors)
}

pub fn use_fetch(service, on_error)
{
	let #(data, set_data) = redraw.use_state([])
	let load_data = redraw.use_callback(fn() {
		handle_service(fn(token) {
			service(token) |> promise.map(result.map_error(_, api_request.map_error(_, dynamic.classify)))
		}, on_error, set_data)
	}, #(service))
	#(data, load_data)
}

pub fn use_fetch_card(initial_value, list_service, on_error)
{
    let #(data, set_data) = redraw.use_state(#(initial_value, []))
    let load_data = redraw.use_callback(fn(id) {
	handle_service(fn(token) {
		list_service(token, id) |> promise.map(result.map_error(_, api_request.map_error(_, dynamic.classify)))
	}, on_error, set_data)
    }, #(list_service))

    #(data, load_data)
}


pub fn use_update_callback(
    service,
    on_success on_success,
    on_error on_error,
)
{
    redraw.use_callback(fn(model, map) {
	handle_service(service(_, model, map), on_error, on_success)
    }, #(service))
}


pub fn use_delete_callback(
    delete_service,
    on_success on_success,
    on_error on_error,
)
{
    redraw.use_callback(fn(model) {
        use confirm <- swal.confirm("Êtes-vous sûr de vouloir supprimer l'élément sélectionné?", "")
        use <- bool.guard(!confirm, Nil)

	handle_service(delete_service(_, model), on_error, on_success)
    }, #(delete_service))
}


pub fn use_paginated_fetch(start_page, list_service, on_error)
{
    let #(page, set_page) = redraw.use_state(start_page)
    let #(#(data, page_count), set_data) = redraw.use_state(#([], 1))
    let load_data = redraw.use_callback(fn(page, filter) {
        set_page(page)
	handle_service(fn(token) {
		list_service(token, page, filter)
			|> promise.map(result.map_error(_, api_request.map_error(_, dynamic.classify)))
	}, on_error, set_data)
    }, #(list_service))

    #(Paginated(data:, page:, page_count:), load_data)
}
