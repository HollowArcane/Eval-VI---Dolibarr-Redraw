import tempo/offset
import tempo/datetime
import tempo/time
import tempo
import tempo/date
import gleam/dynamic/decode
import tempo/error

pub fn iso_datetime_decoder()
{
    use date_str <- decode.then(decode.string)
    case datetime.from_string(date_str)
    {
        Error(_) -> decode.failure(datetime.new(date.current_utc(), time.start_of_day, offset.utc), "IsoDateTime")
        Ok(datetime) -> decode.success(datetime)
    }
}

pub fn datetime_decoder(format: String)
{
    use date_str <- decode.then(decode.string)
    case datetime.parse(date_str, tempo.Custom(format))
    {
        Error(error.DateTimeInvalidFormat(format)) -> decode.failure(
            datetime.new(date.current_utc(), time.start_of_day, offset.utc),
            "InvalidDateTimeFormat:" <> format
        )
        Error(_) -> decode.failure(
            datetime.new(date.current_utc(), time.start_of_day, offset.utc),
            "DateTime:" <> format
        )
        Ok(date) -> decode.success(date)
    }
}

pub fn iso_date_decoder()
{
    use date_str <- decode.then(decode.string)
    case date.parse(date_str, tempo.ISO8601Date)
    {
        Error(_) -> decode.failure(date.current_utc(), "IsoDate")
        Ok(date) -> decode.success(date)
    }
}

pub fn date_decoder(format: String)
{
    use date_str <- decode.then(decode.string)
    case date.parse(date_str, tempo.CustomDate(format))
    {
        Error(error.DateInvalidFormat(format)) -> decode.failure(
            date.current_utc(),
            "InvalidDateFormat:" <> format
        )
        Error(_) -> decode.failure(date.current_utc(), "Date:" <> format)
        Ok(date) -> decode.success(date)
    }
}

pub fn iso_time_decoder()
{
    use date_str <- decode.then(decode.string)
    case time.parse(date_str, tempo.ISO8601TimeSeconds)
    {
        Error(_) -> decode.failure(time.start_of_day, "IsoTime")
        Ok(time) -> decode.success(time)
    }
}

pub fn time_decoder(format: String)
{
    use date_str <- decode.then(decode.string)
    case time.parse(date_str, tempo.CustomTime(format))
    {
        Error(error.TimeInvalidFormat(format)) -> decode.failure(
            time.start_of_day,
            "InvalidTimeFormat:" <> format
        )
        Error(_) -> decode.failure(time.start_of_day, "Time:" <> format)
        Ok(time) -> decode.success(time)
    }
}