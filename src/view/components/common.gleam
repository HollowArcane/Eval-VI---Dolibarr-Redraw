import redraw/dom/attribute
import redraw/dom/html

pub fn title(content)
{ html.h1([attribute.class_name("d-flex align-items-center gap-3")], content) }

pub fn subtitle(content)
{ html.h2([], [html.text(content)]) }

pub fn center_p(text)
{ html.p([attribute.attribute("align", "center")], [html.text(text)]) }