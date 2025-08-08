import toolkit_util/data
import toolkit_util/calendar
import toolkit_util/calendar/time
import toolkit_util/calendar/date

pub type Student
{
    Student(
        i: Int,
        f: Float,
        s: String,
        b: Bool,
        d: date.Date,
        t: time.Time,
        c: calendar.Calendar,
        l: List(String)
    )
}
pub fn format(model: Student)
{
	[
		#("i", model.i |> data.Int),
		#("f", model.f |> data.Float),
		#("s", model.s |> data.String),
		#("b", model.b |> data.Bool),
		#("d", model.d |> data.Date),
		#("t", model.t |> data.Time),
		#("c", model.c |> data.Datetime),
	]
}
