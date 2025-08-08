import view/components/bs5_attributes
import view/components/fa
import redraw
import toolkit_util/bools
import redraw/dom/html
import redraw/dom/attribute
import view/components/bs5
import view/components/mui/dialog
import redraw/dom/events

pub type Data
{
    HTML(content: String)
    Select(value: String, options: List(#(String, String)))
}

pub fn brand()
{
    html.img([
        attribute.src("/img/no-bg-brand0.png"),
        attribute.width(300),
        attribute.class_name("mb-3 mx-5")
    ])
}

pub fn brand_variation()
{
    html.img([
        attribute.src("/img/no-bg-brand1.png"),
        attribute.width(200),
    ])
}

pub fn btn_add(on_click on_click)
{
    btn_primary([
        events.on_click(fn(_) {on_click()}),
        ..bs5_attributes.tooltip("Ajouter")
    ]
    , [
        fa.icon("fa fa-add")
    ])
}

pub fn btn_export_pdf(on_click on_click)
{
    bs5.button(bs5.secondary_danger, [
        events.on_click(fn(_) {on_click()}),
        ..bs5_attributes.tooltip("Exporter PDF")
    ]
    , [
        fa.icon("fa fa-file-pdf")
    ])
}

pub fn btn_primary(attributes, content)
{
    bs5.button(bs5.primary, [
        attribute.class_name("btn btn-primary"),
        attribute.style([
            #("background-color", "#2e3062")
        ]),
        ..attributes
    ], content)
}

pub fn btn_submit(text: String, loading: Bool)
{
    bs5.button(bs5.primary, [
        attribute.class_name("d-flex align-items-center justify-content-center gap-3 btn btn-primary btn-block " <> bools.check(loading, "disabled", "")),
        attribute.style([
            #("background-image", "linear-gradient(-45deg, #ffc700 15%, #2e3062 15%, #2e3062 85%, #ffc700 85%)")
        ])
    ], [
        html.text(text),
        bools.check(loading, bs5.spinner(), redraw.fragment([]))
    ])
}

pub fn modal(
    title title: String,
    open open: Bool,
    on_close on_close: fn() -> Nil,
    children children
)
{
    let view_dialog = dialog.create_element()
    let full_width = True
    let max_width = "sm"

    view_dialog(dialog.Props(open:, on_close:,full_width:,max_width:), [
        html.div([
            attribute.class("border-bottom d-flex align-items-center justify-content-between"),
            attribute.width(600),
        ], [
            html.h2([attribute.class("p-3 pb-2")], [html.text(title)]),
            html.div([
                events.on_click(fn(_) {on_close()}),
                attribute.class("px-3 h-100 fs-3 text-muted"),
            ], [fa.icon("fa fa-close")])
        ]),
        html.div([attribute.class("p-3")], children),
    ])
}