import toolkit_util/results
import gleam/dynamic
import gleam/string
import gleam/dynamic/decode
import gleam/order
import gleam/bool
import gleam/result
import gleam/float
import gleam/int
import toolkit_util/calendar/time.{type Time}
import toolkit_util/calendar/date.{type Date}


pub type Calendar
{ Calendar(date: Date, time: Time) }

pub type Duration
 {
    Year
    Month
    Day
    Hour
    Minute
    Second
    Microsecond
}

pub fn set(calendar: Calendar, quantity: Int, duration: Duration)
{
    case duration
    {
        Year -> set_year(calendar, quantity)
        Month -> set_month(calendar, quantity)
        Day -> set_day(calendar, quantity)
        Hour -> set_hours(calendar, quantity)
        Minute -> set_minutes(calendar, quantity)
        Second -> set_seconds(calendar, quantity)
        Microsecond -> set_micros(calendar, quantity)
    }
}

pub fn add(calendar: Calendar, quantity: Int, duration: Duration)
{
    case duration
    {
        Year -> add_year(calendar, quantity)
        Month -> add_month(calendar, quantity)
        Day -> add_day(calendar, quantity)
        Hour -> add_hours(calendar, quantity)
        Minute -> add_minutes(calendar, quantity)
        Second -> add_seconds(calendar, quantity)
        Microsecond -> add_micros(calendar, quantity)
    }
}

pub fn get(calendar: Calendar, duration: Duration)
{
    case duration
    {
        Year -> get_year(calendar)
        Month -> get_month(calendar)
        Day -> get_day(calendar)
        Hour -> get_hours(calendar)
        Minute -> get_minutes(calendar)
        Second -> get_seconds(calendar)
        Microsecond -> get_micros(calendar)
    }
}

pub fn start_of_year(year: Int)
{ Calendar(date.start_of_year(year), time.start_of_day()) }

pub fn get_year(calendar: Calendar)
{ date.get_year(calendar.date) }

pub fn get_month(calendar: Calendar)
{ date.get_month(calendar.date) }

pub fn get_day(calendar: Calendar)
{ date.get_day(calendar.date) }

pub fn get_hours(calendar: Calendar)
{ time.get_hours(calendar.time) }

pub fn get_minutes(calendar: Calendar)
{ time.get_minutes(calendar.time) }

pub fn get_seconds(calendar: Calendar)
{ time.get_seconds(calendar.time) }

pub fn get_micros(calendar: Calendar)
{ time.get_micros(calendar.time) }

pub fn set_year(calendar: Calendar, quantity: Int)
{ Calendar(..calendar,
    date: date.set_year(calendar.date, quantity)
) }

pub fn set_month(calendar: Calendar, quantity: Int)
{ Calendar(..calendar,
    date: date.set_month(calendar.date, quantity)
) }

pub fn set_day(calendar: Calendar, quantity: Int)
{ Calendar(..calendar,
    date: date.set_day(calendar.date, quantity)
) }

pub fn set_hours(calendar: Calendar, quantity: Int)
{
    let hours = int.modulo(quantity, 24)
        |> result.unwrap(0)
    let days = int.to_float(quantity) /. 24.
        |> float.floor
        |> float.truncate

    Calendar(..add_day(calendar, days),
        time: time.set_hours(calendar.time, hours)
    )
}

pub fn set_minutes(calendar: Calendar, quantity: Int)
{
    let minutes = int.modulo(quantity, 60)
        |> result.unwrap(0)
    let hours = int.to_float(quantity) /. 60.
        |> float.floor
        |> float.truncate

    Calendar(..add_hours(calendar, hours),
        time: time.set_minutes(calendar.time, minutes)
    )
}

pub fn set_seconds(calendar: Calendar, quantity: Int)
{
    let seconds = int.modulo(quantity, 60)
        |> result.unwrap(0)
    let minutes = int.to_float(quantity) /. 60.
        |> float.floor
        |> float.truncate

    Calendar(..add_minutes(calendar, minutes),
        time: time.set_seconds(calendar.time, seconds)
    )
}

pub fn set_micros(calendar: Calendar, quantity: Int)
{
    let micros = int.modulo(quantity, 1_000_000)
        |> result.unwrap(0)
    let seconds = int.to_float(quantity) /. 1_000_000.
        |> float.floor
        |> float.truncate

    Calendar(..add_seconds(calendar, seconds),
        time: time.set_micros(calendar.time, micros)
    )
}

pub fn add_year(calendar: Calendar, quantity: Int)
{ set_year(calendar, date.get_year(calendar.date) + quantity) }

pub fn add_month(calendar: Calendar, quantity: Int)
{ set_month(calendar, date.get_month(calendar.date) + quantity) }

pub fn add_day(calendar: Calendar, quantity: Int)
{ set_day(calendar, date.get_day(calendar.date) + quantity) }

pub fn add_hours(calendar: Calendar, quantity: Int)
{ set_hours(calendar, time.get_hours(calendar.time) + quantity) }

pub fn add_minutes(calendar: Calendar, quantity: Int)
{ set_minutes(calendar, time.get_minutes(calendar.time) + quantity) }

pub fn add_seconds(calendar: Calendar, quantity: Int)
{ set_seconds(calendar, time.get_seconds(calendar.time) + quantity) }

pub fn add_micros(calendar: Calendar, quantity: Int)
{ set_micros(calendar, time.get_micros(calendar.time) + quantity) }

pub fn as_tuple(calendar: Calendar)
{
    #(
        date.get_year(calendar.date),
        date.get_month(calendar.date),
        date.get_day(calendar.date),
        time.get_hours(calendar.time),
        time.get_minutes(calendar.time),
        time.get_seconds(calendar.time),
        time.get_micros(calendar.time)
    )
}

pub fn date_tuple(calendar: Calendar)
{ date.as_tuple(calendar.date) }

pub fn time_tuple(calendar: Calendar)
{ time.as_tuple(calendar.time) }

pub fn compare(c1: Calendar, c2: Calendar)
{
    let date_compaison = date.compare(c1.date, c2.date)
    use <- bool.guard(date_compaison != order.Eq, date_compaison)
    time.compare(c1.time, c2.time)
}

pub fn tuple_decoder()
{
    use date <- decode.field(0, date.tuple_decoder())
    use time <- decode.field(1, time.tuple_decoder())
    decode.success(Calendar(date: date, time: time))
}

pub fn string_decoder()
{
    use str <- decode.then(decode.string)
    let parts = string.split(str, " ")
    case parts
    {
        [date, time] -> {
            use date <- results.guard_error(
                decode.run(dynamic.string(date), date.string_decoder()),
                fn(_) {decode.failure(start_of_year(2000), "YYYY-MM-DD HH:MM:SS")} 
            )
            use time <- results.guard_error(
                decode.run(dynamic.string(time), time.string_decoder()),
                fn(_) {decode.failure(start_of_year(2000), "YYYY-MM-DD HH:MM:SS")} 
            )
            decode.success(Calendar(date: date, time: time))
        }
        _ -> decode.failure(
            start_of_year(2000), 
            "YYYY-MM-DD HH:MM:SS"
        )
    }
}

pub fn to_string(calendar: Calendar)
{ calendar.date |> date.to_string <> " " <> calendar.time |> time.to_string }
