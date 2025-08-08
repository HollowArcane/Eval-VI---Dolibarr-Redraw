import toolkit_util/data
import toolkit_util/calendar/date

pub type Student
{
    Student(
        id: Int,
        name: String,
        date_inscription: date.Date,
    )
}

pub fn format(model: Student)
{
	[
		#("id", model.id |> data.Int),
		#("name", model.name |> data.String),
		#("date_inscription", model.date_inscription |> data.Date)
	]
}
