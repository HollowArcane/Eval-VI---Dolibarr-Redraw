import redraw
import view/components/bs5
import redraw/dom/attribute
import redraw/dom/html

pub const template = "message-template"
pub const id = "#messages"

pub fn element()
{
    redraw.fragment([
        html.template([attribute.id("message-template")], [
            bs5.alert(bs5.info, [], [  
                html.text("{{data}}")
            ])
        ]),
        html.div([attribute.id("messages")],[
        ])
    ])
}