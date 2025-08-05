import redraw


pub type Props
{
    Props(
        open: Bool,
        on_close: fn() -> Nil,
        full_width: Bool,
        max_width: String,
    )
}

@external(javascript, "@mui/material/Dialog", "default")
fn element_ffi(props: Props) -> redraw.Component

pub fn create_element() -> fn(Props, List(redraw.Component)) -> redraw.Component
{ redraw.to_component("Dialog", element_ffi) }
