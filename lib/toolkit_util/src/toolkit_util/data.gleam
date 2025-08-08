import gleam/int
import gleam/float
import gleam/bool
import toolkit_util/calendar/time.{type Time}
import toolkit_util/calendar/date.{type Date}
import toolkit_util/calendar.{type Calendar}

pub type Data(a)
{
    Int(Int)
    Float(Float)
    String(String)
    Bool(Bool)
    Date(Date)
    Time(Time)
    Datetime(Calendar)
    Other(a)
}

pub fn to_string(data: Data(a), other: fn(a) -> String)
{
    case data
    {
        Bool(v) -> bool.to_string(v)
        Date(v) -> date.to_string(v)
        Datetime(v) -> calendar.to_string(v)
        Float(v) -> float.to_string(v)
        Int(v) -> int.to_string(v)
        Other(v) -> other(v)
        String(v) -> v
        Time(v) -> time.to_string(v)
    }
}