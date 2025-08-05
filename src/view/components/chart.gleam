import gleam/list
import redraw/dom/html
import redraw.{type Component}
import redraw/dom/attribute.{attribute}

pub fn simple(id: String, type_: String, labels: List(String), datasets: List(#(String, List(String)))) -> Component
{
    redraw.jsx("chart", [
        attribute.attribute("type", type_),
        attribute.id(id),
    ], [
        redraw.jsx("labels", [],
            labels |> list.map(fn(x) {html.label([], [html.text(x)])})
        ),
        ..datasets |> list.map(fn(dataset: #(String, List(String))) {
            redraw.jsx("dataset", [attribute("name", dataset.0)],
                dataset.1 |> list.map(fn(x) {redraw.jsx("data", [], [html.text(x)])})
            )
        })
    ])
}