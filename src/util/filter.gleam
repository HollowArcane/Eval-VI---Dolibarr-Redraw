import gleam/float
import toolkit_util/data.{type Data}
import toolkit_util/calendar/date
import gleam/string
import gleam/list
import gleam/json

pub type Filter
{
    Filter(String, String, String)
}

pub type FilterData
{
    DateMin(value: date.Date)
    DateMax(value: date.Date)
    FloatMin(value: Float)
    FloatMax(value: Float)
    Empty
}

pub fn filter_data_to_string(data: FilterData)
{
    case data
    {
        DateMax(value:) -> date.to_string(value)
        DateMin(value:) -> date.to_string(value)
        FloatMax(value:) -> float.to_string(value)
        FloatMin(value:) -> float.to_string(value)
        Empty -> ""
    }
}

pub fn to_filters(filters: List(#(String, Data(FilterData))))
{
    use filters, #(field, data) <- list.fold(filters, [])
    case data
    {
        data.Other(Empty) -> filters
        data.Bool(_) |
        data.Date(_) |
        data.Datetime(_) |
        data.Float(_) |
        data.Int(_) |        
        data.Time(_) -> 
            [equals(field, data.to_string(data, filter_data_to_string)), ..filters]
        
        data.String("") -> filters
        
        data.String(data) ->
            [like(field, data), ..filters]
        
        data.Other(DateMin(value:)) -> [gte(field, date.to_string(value)), ..filters]
        data.Other(DateMax(value:)) -> [lt(field, date.to_string(value)), ..filters]
        data.Other(FloatMin(value:)) -> [gte(field, float.to_string(value)), ..filters]
        data.Other(FloatMax(value:)) -> [lt(field, float.to_string(value)), ..filters]
    }
}

pub fn to_query(filters: List(Filter))
{
    "(" <> {
        use filter <- list.map(filters)
        let Filter(field, operator, value) = filter
        "t." <> field <> ":" <> operator <> ":" <> value
    } |> string.join(") and (") <> ")"
}

pub fn to_json(filter)
{
    let Filter(field, operator, value) = filter
    json.array([field, operator, value], json.string)
}

pub fn like(field: String, value: String)
{ Filter(field, "like", "%" <> value <> "%") }

pub fn equals(field: String, value: String)
{ Filter(field, "=", value) }

pub fn gte(field: String, value: String)
{ Filter(field, ">=", value) }

pub fn gt(field: String, value: String)
{ Filter(field, ">", value) }

pub fn lte(field: String, value: String)
{ Filter(field, "<=", value) }

pub fn lt(field: String, value: String)
{ Filter(field, "<", value) }