import toolkit_util/results
import gleam/string
import gleam/dynamic/decode
import gleam/bool
import gleam/float
import gleam/result
import gleam/int

pub opaque type Time
{ Time(hours: Int, minutes: Int, seconds: Int, micros: Int) }

pub type Duration
{
    Hour
    Minute
    Second
    Microsecond
}

pub fn start_of_day()
{ Time(0, 0, 0, 0) }

/// Creates a new Time instance with the specified hours, minutes, seconds, and microseconds.
/// Values out of range are adjusted to fit within the valid ranges for each component and excess values are carried over to the next component.
/// # Arguments
/// * `hours` - The hour of the day (0-23).
/// * `minutes` - The minute of the hour (0-59).
/// * `seconds` - The second of the minute (0-59).
/// * `micros` - The microsecond of the second (0-999999).
/// # Returns
/// A new Time instance representing the specified time of day.
pub fn new(hours: Int, minutes: Int, seconds: Int, micros: Int)
{
    start_of_day()
        |> set_hours(hours)
        |> set_minutes(minutes)
        |> set_seconds(seconds)
        |> set_micros(micros)
}

pub fn strict_new(hours: Int, minutes: Int, seconds: Int, micros: Int)
{
    use <- bool.guard(hours < 0 || hours > 23,
        Error("Hours must be between 0 and 23")
    )
    use <- bool.guard(minutes < 0 || minutes > 59,
        Error("Minutes must be between 0 and 59")
    )
    use <- bool.guard(seconds < 0 || seconds > 59,
        Error("Seconds must be between 0 and 59")
    )
    use <- bool.guard(micros < 0 || micros > 999_999,
        Error("Microseconds must be between 0 and 999999")
    )
    Ok(Time(hours, minutes, seconds, micros))
}

pub fn as_tuple(time: Time)
{ #(time.hours, time.minutes, time.seconds, time.micros) }

pub fn get(time: Time, duration: Duration)
{
    case duration
    {
        Hour -> get_hours(time)
        Minute -> get_minutes(time)
        Second -> get_seconds(time)
        Microsecond -> get_micros(time)
    }
}

pub fn set(time: Time, quantity: Int, duration: Duration)
{
    case duration
    {
        Hour -> set_hours(time, quantity)
        Minute -> set_minutes(time, quantity)
        Second -> set_seconds(time, quantity)
        Microsecond -> set_micros(time, quantity)
    }
}

pub fn add(time: Time, quantity: Int, duration: Duration)
{
    case duration
    {
        Hour -> add_hours(time, quantity)
        Minute -> add_minutes(time, quantity)
        Second -> add_seconds(time, quantity)
        Microsecond -> add_micros(time, quantity)
    }
}

pub fn compare(t1: Time, t2: Time)
{
    use <- bool.guard(t1.hours != t2.hours,
        int.compare(t1.hours, t2.hours)
    )
    use <- bool.guard(t1.minutes != t2.minutes,
        int.compare(t1.minutes, t2.minutes)
    )
    use <- bool.guard(t1.seconds != t2.seconds,
        int.compare(t1.seconds, t2.seconds)
    )
    int.compare(t1.micros, t2.micros)
}

pub fn get_hours(time: Time)
{ time.hours }

pub fn get_minutes(time: Time)
{ time.minutes }

pub fn get_seconds(time: Time)
{ time.seconds }

pub fn get_micros(time: Time)
{ time.micros }

pub fn set_hours(time: Time, hours: Int)
{
    let hours = int.modulo(hours, 24)
        |> result.unwrap(0)
    Time(..time,
        hours:
    )
}

pub fn set_minutes(time: Time, minutes: Int)
{
    let minutes = int.modulo(minutes, 60)
        |> result.unwrap(0)
    let exceed_hours = int.to_float(minutes) /. 60.     
        |> float.floor
        |> float.truncate

    Time(..add_hours(time, exceed_hours),
        minutes:
    )
}

pub fn set_seconds(time: Time, seconds: Int)
{
    let seconds = int.modulo(seconds, 60)
        |> result.unwrap(0)
    let exceed_minutes = int.to_float(seconds) /. 60.
        |> float.floor
        |> float.truncate
    Time(..add_minutes(time, exceed_minutes),
        seconds: seconds
    )
}

pub fn set_micros(time: Time, micros: Int)
{
    let micros = int.modulo(micros, 60)
        |> result.unwrap(0)
    let exceed_seconds = int.to_float(micros) /. 60.
        |> float.floor
        |> float.truncate
    Time(..add_seconds(time, exceed_seconds),
        micros: micros
    )
}

pub fn add_hours(time: Time, hours: Int)
{ set_hours(time, time.hours + hours) }

pub fn add_minutes(time: Time, minutes: Int)
{ set_minutes(time, time.minutes + minutes) }

pub fn add_seconds(time: Time, seconds: Int)
{ set_seconds(time, time.seconds + seconds) }

pub fn add_micros(time: Time, micros: Int)
{ set_micros(time, time.micros + micros) }

pub fn tuple_decoder()
{
    use hours <- decode.field(0, decode.int)
    use minutes <- decode.field(1, decode.int)
    use #(seconds, microseconds) <- decode.field(2, seconds_decoder())
    case strict_new(hours, minutes, seconds, microseconds)
    {
        Ok(time) -> decode.success(time)
        Error(_) -> decode.failure(start_of_day(), "HH:MM:SS")
    }
}

pub fn string_decoder()
{
    use str <- decode.then(decode.string)
    let parts = string.split(str, ":")

    case parts
    {
        [hours, minutes, seconds] -> {
            use hours <- results.guard_error(
                int.parse(hours), 
                fn(_) {decode.failure(start_of_day(), "hours should be an integer")}
            )
            use minutes <- results.guard_error(
                int.parse(minutes), 
                fn(_) {decode.failure(start_of_day(), "minutes should be an integer")}
            )
            use #(seconds, microseconds) <- results.guard_error(
                parse_seconds(seconds), 
                fn(_) {decode.failure(start_of_day(), "seconds should be an integer or a float")}
            )

            case strict_new(hours, minutes, seconds, microseconds)
            {
                Ok(time) -> decode.success(time)
                Error(_) -> decode.failure(start_of_day(), "HH:MM:SS")
            }

        }
        _ ->
            decode.failure(start_of_day(), "HH:MM:SS:MICROS")
    }
}

fn seconds_decoder()
{
    decode.one_of({
        use seconds <- decode.then(decode.int)
        decode.success(#(seconds, 0))
    },[{
        use seconds_and_micros <- decode.then(decode.float)
        let seconds = float.floor(seconds_and_micros)
        let micros = {seconds_and_micros -. seconds} *. 1_000_000.
        decode.success(#(
            float.truncate(seconds),
            float.truncate(micros),
        ))
    }])
}

fn parse_seconds(seconds_and_micros)
{
    result.or({
        use seconds <- result.map(
            int.parse(seconds_and_micros)
        )
        #(seconds, 0)
    }, {
        use seconds_and_micros <- result.map(
            float.parse(seconds_and_micros)
        )
        let seconds = float.floor(seconds_and_micros)
        let micros = {seconds_and_micros -. seconds} *. 1_000_000.
        #(float.truncate(seconds), float.truncate(micros))
    })
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

pub fn to_string(time: Time)
{
    let hh_mm_ss = number_to_string(time.hours) <> ":" <> number_to_string(time.minutes) <> ":" <> number_to_string(time.seconds)
    case time.micros
    {
        0 -> hh_mm_ss
        _ -> hh_mm_ss <> "." <> int.to_string(time.micros)
    }
}