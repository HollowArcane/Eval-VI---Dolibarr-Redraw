import util/chart
import redraw

pub type Props
{
    Props(
        options: chart.ChartOption,
        data: chart.ChartData
    )
}

@external(javascript, "react-chartjs-2", "Doughnut")
fn element_ffi(props: Props) -> redraw.Component

pub fn create_element() -> fn(Props, List(redraw.Component)) -> redraw.Component
{ redraw.to_component("Doughnut", element_ffi) }