import toolkit_util/calendar/time
import gleam/int
import gleam/float
import toolkit_util/calendar
import toolkit_util/calendar/date
import toolkit_util/data.{type Data}
import gleam/string
import gleam/list

pub fn insert(table: String, data: List(#(String, Data(Nil))))
{
	let #(columns, values) = list.unzip(data)
	"INSERT INTO " <> table <> " (" <> string.join(columns, ", ") <> ") VALUES(" <> {values |> list.map(data_to_string) |> string.join(", ")} <> ")"
}

pub fn data_to_string(data: Data(Nil))
{
	case data
	{
		data.Bool(True) -> "TRUE"
		data.Bool(False) -> "FALSE"
		data.Date(v) -> "'" <> date.to_string(v) <> "'"
		data.Datetime(v) -> "'" <> calendar.to_string(v) <> "'"
		data.Float(v) -> v |> float.to_precision(2) |> float.to_string
		data.Int(v) -> int.to_string(v)
		data.Other(Nil) -> "NULL"
		data.String(v) -> "'" <> v <> "'"
		data.Time(v) -> "'" <> time.to_string(v) <> "'"
	}
}
