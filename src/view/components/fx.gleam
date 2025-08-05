import view/components/stock_asap
import toolkit_util/bools
import view/components/bs5
import gleam/list
import redraw/dom/attribute
import redraw/dom/html
import redraw.{type Component}

pub fn table(headers: List(String), body: Component) -> Component
{
    bs5.table([attribute.class_name("fx__table table table-hover shadow")], [
        html.thead([], [
            html.tr([], list.map(headers, fn(header) {
                html.th([], [html.text(header)])
            }))
        ]),
        body
    ])
}

pub fn sidenav(active, title: #(String, String), links: List(#(String, List(#(String, String)))))
{
    html.div(
        [
            attribute.class_name("fx__navbar shadow"),
            attribute.style([
                #("background-image", "linear-gradient(-45deg, #ffc700 30%, #2e3062 30%)")
            ])
        ],
        [
            html.div(
                [attribute.class_name("fx__navbar-brand")],
                [html.h1([], [html.a([attribute.href(title.0)], [stock_asap.brand_variation()])])],
            ),
            ..list.map(links, fn(link) {
                html.div(
                    [attribute.class_name("fx__navbar-section")],
                    [
                        html.h3([attribute.class_name("fx__navbar-subtitle")], [html.text(link.0)]),
                        html.ul(
                            [attribute.class_name("fx__navbar-list")],
                            link.1 |> list.map(fn(link) {sidenav_item(active, link.0, link.1)})
                        ),
                    ],
                )
            })
        ],
    )
}

fn sidenav_item(active: String, href: String, label: String)
{
    html.li([
        attribute.class_name(bools.check(active == href, "active", "")),
    ], [
        html.a([
            attribute.href(href),
            attribute.class_name("fx__navbar-item"),
        ], [
                html.text(label)
        ]) 
    ])
}