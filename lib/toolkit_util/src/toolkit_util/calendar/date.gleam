import gleam/dynamic
import gleam/list
import toolkit_util/lists
import gleam/string
import gleam/dynamic/decode
import gleam/bool
import toolkit_util/recursions
import gleam/float
import gleam/int

pub opaque type Date
{ Date(year: Int, month: Int, day: Int) }

pub type Duration
{
    Year
    Month
    Day
}

pub fn set(date: Date, quantity: Int, duration: Duration)
{
    case duration
    {
        Day -> set_day(date, quantity)
        Month -> set_month(date, quantity)
        Year -> set_year(date, quantity)
    }
}

pub fn add(date: Date, quantity: Int, duration: Duration)
{
    case duration
    {
        Day -> add_day(date, quantity)
        Month -> add_month(date, quantity)
        Year -> add_year(date, quantity)
    }
}

pub fn get(date: Date, duration: Duration)
{
    case duration
    {
        Day -> get_day(date)
        Month -> get_month(date)
        Year -> get_year(date)
    }
}

pub fn compare(d1: Date, d2: Date)
{
    use <- bool.guard(d1.year != d2.year,
        int.compare(d1.year, d2.year)
    )
    use <- bool.guard(d1.month != d2.month,
        int.compare(d1.month, d2.month)
    )
    int.compare(d1.day, d2.day)
}

pub fn start_of_year(year: Int)
{ Date(year, 1, 1) }

pub fn new(year: Int, month: Int, day: Int)
{
    start_of_year(year)
        |> set_month(month)
        |> set_day(day)
}

pub fn strict_new(year: Int, month: Int, day: Int)
{
    use <- bool.guard(month < 1 || month > 12,
        Error("Month must be between 1 and 12")
    )
    let day_limit = days_in_month(month, year)
    use <- bool.guard(day < 1 || day > day_limit,
        Error("Day must be between 1 and " <> int.to_string(day_limit))
    )
    Ok(Date(year, month, day))
}

fn days_in_month(month: Int, year: Int)
{
    case month
    {
        1 -> 31
        2 if
            {year % 4 == 0 && year % 100 != 0} ||
            {year % 400 == 0}
            -> 29
        2 -> 28
        3 -> 31
        4 -> 30
        5 -> 31
        6 -> 30
        7 -> 31
        8 -> 31
        9 -> 30
        10 -> 31
        11 -> 30
        _ -> 31 // December or invalid month defaults to December's days
    }
}

pub fn as_tuple(date: Date)
{ #(date.year, date.month, date.day) }

pub fn get_day(date: Date)
{ date.day }

pub fn get_month(date: Date)
{ date.month }

pub fn get_year(date: Date)
{ date.year }

pub fn set_year(date: Date, year: Int)
{
    let day = int.min(
        date.day,
        days_in_month(date.month, date.year)
    )
    Date(..date, year:, day:)
}

pub fn set_month(date: Date, month: Int)
{
    let exceed_year = int.to_float(month - 1) /. 12.
        |> float.floor
        |> float.truncate
    let month = {month + 11} % 12 + 1
    let day = int.min(
        date.day,
        days_in_month(month, date.year)
    )

    Date(..add_year(date, exceed_year), month:, day:)
}

pub fn set_day(date: Date, day)
{
    use #(date, day) <- recursions.start(#(date, day))
    let day_limit = days_in_month(date.month, date.year)
    case day
    {
        d if d > day_limit ->
            recursions.Continue(#(
                add_month(date, 1),
                d - day_limit
            ))
        d if d <= 0 ->
            recursions.Continue(#(
                add_month(date, -1),
                d + days_in_month({{{date.month - 1} + 11} % 12} + 1, date.year)
            ))
        day -> recursions.End(Date(..date, day:))
    }
}

pub fn add_year(date: Date, quantity: Int)
{ set_year(date, date.year + quantity) }

pub fn add_month(date: Date, quantity: Int)
{ set_month(date, date.month + quantity) }

pub fn add_day(date: Date, quantity: Int)
{ set_day(date, date.day + quantity) }

pub fn tuple_decoder()
{
    use year <- decode.field(0, decode.int)
    use month <- decode.field(1, decode.int)
    use day <- decode.field(2, decode.int)
    case strict_new(year, month, day)
    {
        Ok(date) -> decode.success(date)
        Error(_) -> decode.failure(start_of_year(2000), "YYYY-MM-DD")
    }
}

pub fn string_decoder()
{
    use str <- decode.then(decode.string)
    use parts <- lists.guard_some_error(
        string.split(str, "-")
            |> list.map(int.parse)
    , fn(_) {decode.failure(start_of_year(2000), "YYYY-MM-DD")})

    case parts
    {
        [year, month, day] -> case strict_new(year, month, day)
        {
            Ok(date) -> decode.success(date)
            Error(_) -> decode.failure(start_of_year(2000), "YYYY-MM-DD")
        }
            
        _ ->
            decode.failure(start_of_year(2000), "YYYY-MM-DD")
    }
}

fn number_to_string(value: Int)
{
    let str_value = int.to_string(value)
    case value < 10
    {
        True -> "0" <> str_value
        False -> str_value
    }
}

pub fn to_string(date: Date)
{ int.to_string(date.year) <> "-" <> number_to_string(date.month) <> "-" <> number_to_string(date.day) }

pub fn parse(str: String)
{ decode.run(dynamic.string(str), string_decoder()) }