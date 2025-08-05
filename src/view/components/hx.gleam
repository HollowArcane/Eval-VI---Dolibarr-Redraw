import gleam/int
import gleam/list
import gleam/string
import redraw/dom/attribute.{attribute}

pub opaque type Content
{ Content(swap: String) }

pub opaque type Trigger
{ Trigger(event: String) }

pub opaque type TriggerModifier
{ TriggerModifier(inner: String) }

pub opaque type Sync
{ Sync(event: String) }

pub const this = "this"

pub const inner_html = Content("innerHTML")
pub const outer_html = Content("outerHTML")
pub const after_begin = Content("afterbegin")
pub const before_begin = Content("beforebegin")
pub const after_end = Content("afterend")
pub const before_end = Content("beforeend")
pub const delete_target = Content("delete")
pub const none = Content("none")

pub const click = Trigger("click")
pub const change = Trigger("change")
pub const submit = Trigger("submit")
pub const mouseenter = Trigger("mouseenter")
pub const mouseleave = Trigger("mouseleave")
pub const keyup = Trigger("keyup")
pub const keydown = Trigger("keydown")
pub const load = Trigger("load")

pub const drop = Sync("drop")
pub const abort = Sync("abort")
pub const replace = Sync("replace")
pub const queue = Sync("queue")
pub const queue_first = Sync("queue first")
pub const queue_last = Sync("queue last")
pub const queue_all = Sync("queue all")

pub fn get(path: String)
{ attribute("hx-get", path) }

pub fn put(path: String)
{ attribute("hx-put", path) }

pub fn patch(path: String)
{ attribute("hx-patch", path) }

pub fn delete(path: String)
{ attribute("hx-delete", path) }

pub fn post(path: String)
{ attribute("hx-post", path) }

pub fn indicator(selector: String)
{ attribute("hx-indicator", selector) }

pub fn swap(content: Content)
{ attribute("hx-swap", content.swap) }

pub fn trigger(trigger: Trigger, modifiers: List(TriggerModifier))
{ attribute("hx-trigger", [
    trigger.event, ..list.map(modifiers, fn(m) {m.inner})
] |> string.join(" ")) }

pub const trigger_changed = TriggerModifier("changed") 
pub fn trigger_delay(millis delay: Int)
{ TriggerModifier("delay:" <> int.to_string(delay) <> "ms") }

pub fn trigger_throttle(millis throttle: Int)
{ TriggerModifier("throttle:" <> int.to_string(throttle) <> "ms") }

pub fn trigger_from(from selector: String)
{ TriggerModifier("from:" <> selector) }

pub fn target(selector: String)
{ attribute("hx-target", selector) }

pub fn target_code(code: Int, selector: String)
{
    let code = int.to_string(code)
    let code = case string.length(code )
    {
        length if length < 3 -> code <> "*"
        _ -> code
    }
    attribute("hx-target-" <> code, selector)
}

pub fn ext(extensions)
{ attribute("hx-ext", string.join(extensions, " ")) }

pub fn sync(selector, sync: Sync)
{ attribute("hx-params", selector <> ":" <> sync.event) }

pub fn params(params: List(String))
{ attribute("hx-params", string.join(params, ",")) }

pub fn include(selector: String)
{ attribute("hx-include", selector) }

pub fn preserve()
{ attribute("hx-preserve", "") }

pub fn target_find(selector: String)
{ attribute("hx-target", "find " <> selector) }

pub fn template(id: String)
{ attribute("mustache-template", id) }

pub fn disabled_elt(selector: String)
{ attribute("hx-disabled-elt", selector) }