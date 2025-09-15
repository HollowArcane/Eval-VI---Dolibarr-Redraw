import gleam/int
import gleam/list
import gleam/result
import redraw
import redraw/dom/attribute
import redraw/dom/events
import redraw/dom/html
import util/events as custom_events
import util/pagination
import view/components/bs5
import view/components/fa
import view/components/generic
import view/components/stock_asap

pub fn not_found()
{ title([html.text("Not Found")]) }

pub fn title(content)
{
    html.h1(
        [attribute.class_name("d-flex align-items-center gap-3 mb-3")],
        content,
    )
}

pub fn subtitle(content)
{
    html.h2([], [html.text(content)])
}

pub fn center_p(text)
{
    html.p([attribute.attribute("align", "center")], [html.text(text)])
}

pub fn pagination(active_page, set_page, page_count)
{
    let pages = pagination.spread(active_page, page_count, 2, 2)
    html.div([attribute.class("ms-auto")], [
        bs5.pagination([
            bs5.page_item(
                False,
                [events.on_click(fn(_) { set_page(int.max(active_page - 1, 1)) })],
                [fa.icon("fa fa-chevron-left")],
            ),
            redraw.fragment({
                let active_page = int.to_string(active_page)
                use page <- list.map(pages)
                bs5.page_item(
                    page == active_page,
                    [
                        events.on_click(fn(_) {
                            let _ = int.parse(page) |> result.map(set_page)
                            Nil
                        }),
                    ],
                    [html.text(page)],
                )
            }),
            bs5.page_item(
                False,
                [
                    events.on_click(fn(_) {
                        set_page(int.min(active_page + 1, page_count))
                    }),
                ],
                [fa.icon("fa fa-chevron-right")],
            ),
        ]),
    ])
}

pub fn table(
  data,
  loading loading,
  on_update on_update,
  on_delete on_delete,
  on_export_pdf on_export_pdf,
) {
	case loading, generic.render_table(data, on_update:, on_delete:, on_export_pdf:)
    {
        True, _ ->
            html.div([attribute.class("d-flex justify-content-center")], [
                stock_asap.loader(),
            ])
        _, Ok(table) -> table
        _, Error(_) -> center_p("Aucune donnée trouvée")
  }
}

pub fn form(
    submitting submitting,
    errors errors,
    reset_errors reset_errors,
    on_submit on_submit,
    content content,
) {
        html.form([custom_events.on_submit_object(fn(model) {
            reset_errors()
            on_submit(model)
        } )], [
            redraw.fragment(content(errors)),
            stock_asap.btn_submit("Valider", submitting),
        ])
}
