import view/components/bs5
import toolkit_util/numbers
import util/route
import view/components/stock_asap
import view/components/fa
import redraw/dom/attribute
import view/components/fx
import redraw/dom/html
import gleam/list
import gleam/result
import toolkit_util/data.{type Data}

pub fn render_table(
    data: List(List(#(String, Data(stock_asap.Data(a))))),
    on_delete on_delete,
    on_update on_update,
    on_export_pdf on_export_pdf)
{
    use first <- result.try(list.first(data))
    let #(keys, _) = list.unzip(first)

    Ok(fx.table(keys, html.tbody([], list.map(data, fn(row) {
        html.tr([], list.map(row, fn(format) {
            format_to_td(format.1, on_delete:, on_update:, on_export_pdf:)
        }))
    }))))
}


fn format_to_td(
    format: Data(stock_asap.Data(a)),
    on_delete on_delete,
    on_update on_update,
    on_export_pdf on_export_pdf,
)
{
    case format
    {
        data.Bool(_) | data.Float(_) | data.Int(_) ->
            html.td([attribute.class_name("text-end")], [
                render_element(format, on_delete:, on_update:, on_export_pdf:)
            ])

        data.Other(stock_asap.HTML(html)) ->
            html.td([attribute.dangerously_set_inner_html(attribute.inner_html(html))], [])
        
        _ -> html.td([], [render_element(format, on_delete:, on_update:, on_export_pdf:,
        )])
    }
}

pub fn render_element(
    format: Data(stock_asap.Data(a)),
    on_delete on_delete,
    on_update on_update,
    on_export_pdf on_export_pdf,
)
{
    case format
    {
        data.Bool(True) ->
            fa.icon("fa fa-check")

        data.Bool(False) ->
            fa.icon("fa fa-times")

        data.Other(stock_asap.BtnDelete(model)) -> 
            stock_asap.btn_delete(on_click: fn() {on_delete(model)})

        data.Other(stock_asap.BtnUpdate(title:, icon:, model:, update:)) -> 
            stock_asap.btn_update(title:, icon:, on_click: fn() {on_update(model, update)})

        data.Other(stock_asap.BtnExportPDF(model:)) -> 
            stock_asap.btn_export_pdf(on_click: fn() {on_export_pdf(model)})

        data.Other(stock_asap.BtnGoto(path:)) -> 
            stock_asap.btn_export_json(on_click: fn() {route.go_to(path)})

	data.Other(stock_asap.Badge(text:, variant:)) -> 
		bs5.badge(variant, text)

        // data.Other(stock_asap.Select(value:, options:)) -> {
        //     case options |> list.key_find(value)
        //     {
        //         Error(_) -> redraw.fragment([])
        //         Ok(value) -> bs5.badge(bs5.info, value)
        //     }
        // }

        data.Float(value) ->
            html.text(numbers.format(value, numbers.simple_format2))
        _ ->
            html.text(data.to_string(format, fn(_) {""}))
    }
}
