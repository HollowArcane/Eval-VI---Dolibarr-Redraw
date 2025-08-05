import redraw/dom/attribute

pub fn tooltip(message: String)
{
    [
        attribute.attribute("data-mdb-tooltip-init", ""),
        attribute.attribute("title", message),
    ]
}

pub fn modal_target(target: String)
{
    [
        attribute.attribute("data-mdb-target", "#" <> target),
        attribute.attribute("data-mdb-modal-init", "")
    ]
}

pub fn offcanvas_target(target: String)
{
    [
        attribute.attribute("data-mdb-target", "#" <> target),
        attribute.attribute("data-mdb-button-init", ""),
        attribute.attribute("data-mdb-toggle", "offcanvas"),
        attribute.attribute("aria-controls", target),
    ]
}