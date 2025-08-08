import toolkit_util/data
import toolkit_util/calendar/date

pub type Customer
{
    Customer(
        id: Int,
        name: String,
        email: String,
        phone: String,
        address: String,
        date_joined: date.Date,
    )
}
pub fn format(model: Customer)
{
	[
		#("id", model.id |> data.Int),
		#("name", model.name |> data.String),
		#("email", model.email |> data.String),
		#("phone", model.phone |> data.String),
		#("address", model.address |> data.String),
		#("date_joined", model.date_joined |> data.Date)
	]
}
