import gleam/function
import view/components/generic
import model/common_model.{type Id}
import util/common_utils
import gleam/dynamic/decode
import gleam/json
import gleam/list
import hooks/common_hooks.{Paginated}
import redraw
import redraw/dom/attribute
import redraw/dom/html
import util/errors
import util/export
import util/swal
import view/components/bs5
import view/components/common
import view/components/stock_asap
import view/templates/template
import web/hooks

pub fn create_import_form(
	reset reset,
	on_submit on_submit,
	service service,
	success_message success_message,
	then then,
)
{
	create_form(reset:, on_submit:, service:, success_message:, then:, render: {
		use errors <- function.identity
		[
			case errors |> errors.all
				{
				[] -> redraw.fragment([])
				errors -> bs5.alert(bs5.danger, [], [
					html.ul([], {
					use error <- list.map(errors)
					html.li([], [html.text(error)])
				}),
				])
			},
			bs5.file_input("Fichier", "", [attribute.name("file")]),
		]
	})
}

pub fn create_form(
	reset reset,
	on_submit on_submit,
	service service,
	success_message success_message,
	then then,
	render render,
)
{
	let #(message, set_message) = redraw.use_state(#(bs5.success, ""))
	redraw.use_effect(fn() {
		case reset
		{
			True -> set_message(#(bs5.secondary, ""))
			False -> Nil
		}
	}, #(reset))

	let #(
		creating,
		on_create,
		create_errors,
		reset_create_errors,
	) = common_hooks.use_form_callback(
		on_submit:,
		on_valid: service,
		on_error: fn(message) {
			set_message(#(bs5.danger, message))
		},
		on_success: fn(_) {
			case success_message
			{
				"" -> Nil
				_ -> set_message(#(bs5.success, success_message))
			}
			then()
		},
	)

	let #(alert_variant, alert_message) = message
	use errors <- common.form(
		on_submit: on_create,
		submitting: creating,
		errors: create_errors,
		reset_errors: reset_create_errors
	)
	[
		case alert_message
			{
			"" -> redraw.fragment([])
			_ -> bs5.alert(alert_variant, [], [html.text(alert_message)])
		},
		..render(errors)
	]
}

pub fn create_crud_plus(
    id id: String,
    title title: String,
    get_ref get_ref,
    create_service create_service,
    read_service read_service,
    update_service update_service,
    delete_service delete_service,
    import_service import_service,
    default_filter default_filter,
    form_decoder form_decoder,
    csv_handler csv_handler,
    filter_decoder filter_decoder,
    view_format view_format,
    pdf_list_format pdf_list_format,
    pdf_card_format pdf_card_format,
    csv_format csv_format,
    json_format json_format,
    render_create render_create,
    render_search render_search,
) {
    let #(filter, set_filter) = redraw.use_state(default_filter)
    let #(Paginated(data:, page:, page_count:), set_page) =
        common_hooks.use_paginated_fetch(1, read_service, swal.error("Erreur", _))
    let #(table_loading, set_table_loading) = redraw.use_state(True)
    common_hooks.use_update(fn() { set_table_loading(False) }, #(data))

    let set_page = redraw.use_callback(fn(page) {
        set_table_loading(True)
        set_page(page, filter)
    }, #(filter))

    
    let #(open_create, set_open_create) = redraw.use_state(False)
    let #(open_import, set_open_import) = redraw.use_state(False)
    let #(open_search, set_open_search) = redraw.use_state(False)


    let on_update =
        common_hooks.use_update_callback(
            update_service,
            on_error: swal.error("Erreur", _),
            on_success: fn(_) {
                set_page(1)
            },
        )

    let on_delete =
        common_hooks.use_delete_callback(
            delete_service,
            on_error: swal.error("Erreur", _),
            on_success: fn(_) {
                swal.success("Succès", title <> " supprimé avec succès")
                set_page(1)
            },
        )

  hooks.use_init_effect(fn() { set_page(page) }, #(page))

  template.home(
    "/" <> id,
    html.div([], [
	stock_asap.modal(
		"Insertion " <> title,
		open_create,
		fn() {set_open_create(False)},
		[create_form(
			!open_create,
			decode.run(_, form_decoder()),
			create_service,
			title <> " inséré avec succès",
			fn() {set_page(1)},
			render_create
		)]
	),
	stock_asap.modal(
		"Import " <> title,
		open_import,
		fn() {set_open_import(False)},
		[create_import_form(
			!open_import,
			csv_handler,
			import_service,
			title <> "s importés avec succès",
			fn() {set_page(1)},
		)]
	),
	stock_asap.modal(
		"Recherche " <> title <> "s",
		open_search,
		fn() {set_open_search(False)},
		[create_form(
			!open_search,
			decode.run(_, filter_decoder()),
			fn(_, filter) {
				common_utils.promise(fn() {Ok(set_filter(filter))})
			},
			"",
			fn() {set_page(1)},
			render_search
		)]
	),
        common.title([
            stock_asap.btn_add(fn() {set_open_create(True)}),
            stock_asap.btn_search(fn() {set_open_search(True)}),
            stock_asap.btn_import_csv(fn() {set_open_import(True)}),
            stock_asap.btn_export_pdf(fn() {
                export.pdf_list(
                    "Liste des " <> title <> "s",
                    list.map(data, pdf_list_format),
                )
            }),
            stock_asap.btn_export_csv(fn() {
                export.csv(id <> "s", list.map(data, csv_format))
            }),
            stock_asap.btn_export_json(fn() {
                export.json(id <> "s", json.array(data, json_format))
            }),
            html.text("Liste des " <> title <> "s"),
            common.pagination(page, set_page, page_count)
        ]),
        common.table(
            list.map(data, view_format),
            loading: table_loading,
            on_delete:,
	    on_update:,
            on_export_pdf: fn(model) {
                export.pdf_card(
                    title <> ": " <> get_ref(model),
                    pdf_card_format(model)
                )
            },
        ),
    ]),
  )
}

pub fn create_list(
    id id: String,
    title title: String,
    read_service read_service,
    default_filter default_filter,
    view_format view_format,
) {
    let #(Paginated(data:, page:, page_count:), set_page) =
        common_hooks.use_paginated_fetch(1, read_service, swal.error("Erreur", _))
    let #(table_loading, set_table_loading) = redraw.use_state(True)
    common_hooks.use_update(fn() { set_table_loading(False) }, #(data))

    let set_page = redraw.use_callback(fn(page) {
        set_table_loading(True)
        set_page(page, default_filter)
    }, #())

    common_hooks.use_init(fn() { set_page(page) }, #(page))

    template.home(
        "/" <> id,
        html.div([], [
            common.title([
                html.text("Liste des " <> title <> "s"),
                common.pagination(page, set_page, page_count)
            ]),
            common.table(
                list.map(data, view_format),
                loading: table_loading,
                on_delete: fn(_) {Nil},
                on_export_pdf: fn(_) {Nil},
            	on_update: fn(_, _) {Nil}),
        ]),
    )
}

pub fn create_card(
    path path: String,
    id id: Id(model),
    title title: String,
    initial_data initial_data: model,
    read_service read_service,
    parent_view_format parent_view_format,
    child_view_format child_view_format
) {
    let #(data, load_data) = common_hooks.use_fetch_card(initial_data, read_service, swal.error("Erreur", _))
    let #(parent, children) = data
    let #(table_loading, set_table_loading) = redraw.use_state(True)
    common_hooks.use_update(fn() { set_table_loading(False) }, #(data))

    let load_data = redraw.use_callback(fn(id) {
        set_table_loading(True)
        load_data(id)
    }, #())

    common_hooks.use_init(fn() { load_data(id) }, #(id))

    template.home(
        "/" <> path,
        html.div([], [
            bs5.card([], [
                common.title([
                    html.text("Fiche " <> title),
                ]),
                html.hr([]),
                html.div([attribute.class("mb-5 mr-5")], {
                    use #(header, data) <- list.map(parent_view_format(parent))
                    html.div([attribute.class("d-flex justify-content-between py-3 border-bottom")], [
                        html.span([attribute.class("text-uppercase fw-bold text-muted")], [html.text(header)]),
                        html.span([], [generic.render_element(data, on_update: fn(_, _) {Nil}, on_delete: fn(_) {Nil}, on_export_pdf:  fn(_) {Nil})]),
                    ])
                }),
                common.table(
                    list.map(children, child_view_format),
                    loading: table_loading,
                    on_update: fn(_, _) {Nil},
                    on_delete: fn(_) {Nil},
                    on_export_pdf: fn(_) {Nil},
                ),
            ]),
        ]),
    )
}
