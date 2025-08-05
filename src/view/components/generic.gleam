import view/components/bs5
import redraw
import view/components/stock_asap
import view/components/fa
import redraw/dom/attribute
import view/components/fx
import redraw/dom/html
import gleam/list
import gleam/result
import toolkit_util/data.{type Data}

pub fn render_table(data: List(a), format: fn(a) -> List(#(String, Data(stock_asap.Data))))
{
    use first <- result.try(list.first(data))
    let #(keys, _) = list.unzip(format(first))

    Ok(fx.table(keys, html.tbody([], list.map(data, fn(row) {
        html.tr([], list.map(format(row), fn(format) {
            format_to_td(format.1)
        }))
    }))))
}

fn format_to_td(format: Data(stock_asap.Data))
{
    case format
    {
        data.Bool(_) | data.Float(_) | data.Int(_) ->
            html.td([attribute.class_name("text-end")], [
                render_element(format)
            ])

        data.Other(stock_asap.HTML(html)) ->
            html.td([attribute.dangerously_set_inner_html(attribute.inner_html(html))], [])
        
        _ -> html.td([], [render_element(format)])
    }
}

pub fn render_element(format: Data(stock_asap.Data))
{
    case format
    {
        data.Bool(True) ->
            fa.icon("fa fa-check")

        data.Bool(False) ->
            fa.icon("fa fa-times")

        data.Other(stock_asap.Select(value:, options:)) -> {
            case options |> list.key_find(value)
            {
                Error(_) -> redraw.fragment([])
                Ok(value) -> bs5.badge(bs5.info, value)
            }
        }

        _ ->
            html.text(data.to_string(format, fn(_) {""}))
    }
}
