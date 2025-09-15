import toolkit_util/calendar/time
import toolkit_util/calendar/date
import toolkit_util/calendar.{Calendar}
import gleam/time/calendar.{Date, TimeOfDay} as gcalendar
import gleam/time/timestamp

pub fn now()
{
	let #(
		Date(year:, month:, day:),
		TimeOfDay(hours:, minutes:, seconds:, nanoseconds:)
	) = timestamp.system_time()
		|> timestamp.to_calendar(gcalendar.utc_offset)

	Calendar(
		date.new(year, gcalendar.month_to_int(month), day),
		time.new(hours, minutes, seconds, nanoseconds / 1000)
	)
}
