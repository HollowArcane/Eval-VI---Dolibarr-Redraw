pub opaque type Type
{ Type(name: String) }

pub const line = Type("line")
pub const bar = Type("bar")
pub const doughnut = Type("doughnut")
pub const pie = Type("pie")

pub type ChartOption
pub type ChartData

pub type Dataset
{
    Dataset(
        label: String,
        data: List(Float),
    )
}

pub type Data
{
    Data(
        labels: List(String),
        datasets: List(Dataset)
    )
}

@external(javascript, "../chart_ffi.mjs", "setup")
pub fn setup(model: Data) -> #(ChartData, ChartOption)