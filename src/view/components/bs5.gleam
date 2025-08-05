import gleam/list
import toolkit_util/bools
import gleam/string
import redraw/dom/attribute.{type Attribute, attribute}
import redraw.{type Component}
import redraw/dom/html

pub opaque type Variant
{
    Variant(name: String)
}

pub const primary = Variant("primary")
pub const secondary = Variant("secondary")
pub const secondary_secondary = Variant("secondary_secondary")
pub const secondary_danger = Variant("secondary text-danger")
pub const secondary_info = Variant("secondary text-info")
pub const secondary_warning = Variant("secondary text-warning")
pub const secondary_success = Variant("secondary text-success")
pub const info = Variant("info")
pub const warning = Variant("warning")
pub const danger = Variant("danger")
pub const success = Variant("success")
pub const light = Variant("light")
pub const dark = Variant("dark")

pub fn col_2(children: List(Component))
{
    html.div([
        attribute.class_name("row"),
    ], list.map(children, fn(e) {
        html.div([
            attribute.class_name("col-md-6")
        ], [e])
    }))
}

pub fn col_3(attributes: List(Attribute), children: List(Component))
{
    html.div([
        attribute.class_name("row"),
        ..attributes
    ], list.map(children, fn(e) {
        html.div([
            attribute.class_name("col-md-4")
        ], [e])
    }))
}

pub fn col_4(attributes: List(Attribute), children: List(Component))
{
    html.div([
        attribute.class_name("row"),
        ..attributes
    ], list.map(children, fn(e) {
        html.div([
            attribute.class_name("col-md-4 col-xl-3")
        ], [e])
    }))
}

pub fn label(label: String, value)
{
    html.p([], [
        html.b([], [html.text(label)]),
        value
    ])
}

pub fn center_screen(children: List(Component))
{
    html.div([
        attribute.class_name("d-flex justify-content-center align-items-center"),
        attribute.style([#("height", "100dvh")]),
    ], children)
}

pub fn container(children: List(Component))
{
    html.div([
        attribute.class_name("container mt-3"),
    ], children)
}

pub fn pagination(pages)
{
    html.nav(
        [
            attribute("aria-label", "Page navigation"),
            attribute.class_name("d-flex justify-content-center")
        ],
        [html.ul([
            attribute.class_name("pagination"),
            attribute.id("pagination")
        ], pages)],
    )
}

pub fn link_button(variant: Variant, attributes: List(Attribute), children: List(Component)) -> Component
{
    html.a(
        [
            attribute.class_name("btn btn-" <> variant.name),
            attribute.attribute("data-mdb-ripple-init", ""),
            ..attributes    
        ],
        children
    )
}

pub fn badge(variant: Variant, text: String)
{ html.span([attribute.class_name("badge badge-" <> variant.name)], [html.text(text)]) }

pub fn button(variant: Variant, attributes: List(Attribute), children: List(Component)) -> Component
{
    html.button(
        [
            attribute.class_name("btn btn-" <> variant.name),
            attribute.attribute("data-mdb-ripple-init", ""),
            ..attributes    
        ],
        children
    )
}

pub fn spinner()
{
    html.span(
        [
            attribute.role("status"),
            attribute.class_name("spinner-border"),
        ],
        [html.span([attribute.class_name("visually-hidden")], [html.text("Loading...")])],
    )
}

pub fn table(attributes: List(Attribute), children: List(Component)) -> Component
{
    html.table(
        [
            attribute.class_name("table table-striped table-hover"),
            ..attributes    
        ],
        children
    )
}

pub fn headed_card(name: String, title: String, children: List(Component)) -> Component
{
    html.div(
        [
            attribute.id(name),
            attribute.class_name("card")
        ],
        [
            html.div(
                [attribute.class_name("card-header")],
                [
                    html.h5(
                        [
                            attribute.id(name <> "label"),
                            attribute.class_name("modal-title"),
                        ],
                        [html.text(title)],
                    ),
                ],
            ),
            html.div([attribute.class_name("card-body")], children),
        ]
    )
}

pub fn card(attributes, children: List(Component)) -> Component
{
    html.div(
        [ attribute.class_name("card")],
        [ html.div([attribute.class_name("card-body"), ..attributes], children)]
    )
}

pub fn card_form(attributes: List(Attribute), children: List(Component)) -> Component
{
    html.form(
        [ attribute.class_name("card"), ..attributes],
        [ html.div([attribute.class_name("card-body")], children)]
    )
}

pub fn modal(name: String, title: String, children: List(Component)) -> Component
{
    html.div(
    [
        attribute.attribute("aria-hidden", "true"),
        attribute.attribute("aria-labelledby", name <> "-label"),
        attribute.attribute("tabIndex", "-1"),
        attribute.id(name),
        attribute.class_name("modal fade"),
    ],
    [
        html.div(
        [attribute.class_name("modal-dialog")],
        [
            html.div(
            [attribute.class_name("modal-content")],
            [
                html.div(
                [attribute.class_name("modal-header")],
                [
                    html.h5(
                    [
                        attribute.id(name <> "label"),
                        attribute.class_name("modal-title"),
                    ],
                    [html.text(title)],
                    ),
                    html.button(
                    [
                        attribute.attribute("aria-label", "Close"),
                        attribute.attribute("data-mdb-dismiss", "modal"),
                        attribute.attribute("data-mdb-ripple-init", ""),
                        attribute.class_name("btn-close"),
                        attribute.type_("button"),
                    ],
                    [],
                    ),
                ],
                ),
                html.div([attribute.class_name("modal-body")], children),
            ],
            ),
        ],
        ),
    ],
    )
}


pub fn alert(variant: Variant, attributes, children)
{
    html.div(
        [
            attribute.class_name("alert alert-" <> variant.name),
            ..attributes    
        ],
        children
    )
}

pub fn select(options options: List(#(String, String)), label label: String, error error: String, attributes attributes: List(Attribute))
{
    let name = string.lowercase(label) |> string.replace(" ", "-")
    let invalid = error == ""

    html.div([attribute.class_name("mb-3")], [
        html.label(
            [
                attribute.class_name("form-label " <> bools.check(invalid, "", "is-invalid")),
                attribute.for(name),
            ],
            [html.text(label)]
        ),
        html.select(
            [
                attribute.class_name("form-select"),
                attribute.name(name),
                attribute.id(name),
                ..attributes
            ],
            options |> list.map(fn(option) {
                html.option([attribute.value(option.0)], [html.text(option.1)])
            })
        ),
        html.div([attribute.class_name("invalid-feedback")], [html.text(error)])
    ])
}

pub fn file_input(label, error, attributes)
{ input("file", label:, error:, attributes:) }

pub fn text_input(label, error, attributes)
{ input("text", label:, error:, attributes:) }

pub fn password_input(label, error, attributes)
{ input("password", label:, error:, attributes:) }

pub fn number_input(label, error, attributes)
{ input("number", label:, error:, attributes:) }

pub fn date_input(label, error, attributes)
{ input("date", label:, error:, attributes:) }

pub fn textarea(label label: String, error error: String, attributes attributes: List(Attribute))
{
    let invalid = error == ""

    html.div([attribute.class_name("mb-3")], [
        html.label(
            [ attribute.class_name("form-label"), ],
            [html.text(label)]
        ),
        html.textarea(
            [
                attribute.class_name("form-control " <> bools.check(invalid, "", "is-invalid")),
                ..attributes
            ], []
        ),
        html.div([attribute.class_name("invalid-feedback")], [html.text(error)])
    ])
}

pub fn input(type_ type_: String, label label: String, error error: String, attributes attributes: List(Attribute))
{
    let invalid = error == ""

    html.div([attribute.class_name("mb-3")], [
        html.label(
            [ attribute.class_name("form-label"), ],
            [html.text(label)]
        ),
        html.input(
            [
                attribute.type_(type_),
                attribute.class_name("form-control " <> bools.check(invalid, "", "is-invalid")),
                ..attributes
            ]
        ),
        html.div([attribute.class_name("invalid-feedback")], [html.text(error)])
    ])
}

pub fn checkbox(value value: String, label label: String, attributes attributes: List(Attribute))
{
    let name = string.lowercase(label) |> string.replace(" ", "")
    html.div([attribute.class_name("mb-3")], [
        html.input(
            [
                attribute.type_("checkbox"),
                attribute.class_name("form-check-input"),
                attribute.value(value),
                attribute.name(name),
                attribute.id(name),
                ..attributes
            ]
        ),
        html.label(
            [
                attribute.class_name("form-check-label"),
                attribute.for(name),
            ],
            [html.text(label)]
        ),
    ])
}

pub fn off_canvas(name name: String, title title: String, chidlren children: List(Component))
{
    html.div(
    [
        attribute("aria-labelledby", name <> "Label"),
        attribute.id(name),
        attribute("tabIndex", "-1"),
        attribute.class_name("offcanvas offcanvas-start"),
    ],
    [
        html.div(
            [attribute.class_name("offcanvas-header")],
            [
                html.h5(
                [
                    attribute.id(name <> "Label"),
                    attribute.class_name(title),
                ], []),
                html.button(
                [
                    attribute("aria-label", "Close"),
                    attribute("onclick", "document.getElementById('" <> name <> "').class_nameList.remove('show')"),
                    attribute.class_name("btn-close text-reset"),
                    attribute("data-mdb-ripple-init", ""),
                    attribute("data-mdb-button-init", ""),
                    attribute.type_("button"),
                ],
                [],
                ),
            ],
        ),
        html.div([attribute.class_name("offcanvas-body")], children),
    ],
    )
}