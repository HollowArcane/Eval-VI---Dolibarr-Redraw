import redraw/dom/attribute
import redraw.{type Component}
import redraw/dom/html

pub fn icon(class: String) -> Component
{
    html.i([attribute.class_name(class)], [])
}