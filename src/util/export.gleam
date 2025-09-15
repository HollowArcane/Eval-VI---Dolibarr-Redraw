import gleam/int
import toolkit_util/calendar/time
import toolkit_util/numbers
import toolkit_util/calendar
import toolkit_util/calendar/date
import gleam/bool
import gleam/json.{type Json}
import given
import gleam/string_tree
import gleam/list
import toolkit_util/data.{type Data}
import view/components/stock_asap


pub fn pdf_to_string(data: Data(stock_asap.Data(a)))
{
	case data
	{
		data.Bool(value) -> bool.to_string(value)
		data.Date(value) -> date.to_string(value)
		data.Datetime(value) -> calendar.to_string(value)
		data.Float(value) -> numbers.format(value, numbers.simple_format2)
		data.Int(value) -> int.to_string(value)
		data.Other(value) -> case value
		{
			stock_asap.BtnDelete(_) -> ""
			stock_asap.BtnExportPDF(model:_) -> ""
			stock_asap.BtnGoto(path:_) -> ""
			stock_asap.HTML(content:) -> content
			stock_asap.Badge(text:, variant:_) -> text
			stock_asap.BtnUpdate(title:_, icon:_, model:_, update:_) -> ""
		}
		data.String(value) -> value
		data.Time(value) -> time.to_string(value)
	}
}



@external(javascript, "../html2pdf_ffi.mjs", "generateTable")
pub fn pdf_list(title: String, data: List(List(#(String, Data(stock_asap.Data(a)))))) -> Nil

@external(javascript, "../html2pdf_ffi.mjs", "generateCard")
pub fn pdf_card(title: String, data: List(#(String, Data(stock_asap.Data(a))))) -> Nil

@external(javascript, "../export_ffi.mjs", "exportData")
fn export_string(filename: String, content_type: String, data: String) -> Nil

pub fn json(title: String, data: Json)
{ export_string(title <> ".json", "application/json", data |> json.to_string) }


pub fn csv(title: String, data: List(List(#(String, Data(Nil)))))
{
    let csv = {
        use first_row <- given.ok(list.first(data), fn(_) {""})
        let #(keys, _) = first_row |> list.unzip

        let string = keys
            |> list.map(string_tree.from_string)
            |> string_tree.join("\",\"")
            |> string_tree.prepend("\"")
            |> string_tree.append("\"\n")

        {
            use row <- list.map(data)
            {
                use #(_, value) <- list.map(row)
                let str_value = data.to_string(value, fn(_) {""})
                case value
                {
                    data.Bool(_) | data.Int(_) | data.Float(_) | data.Other(Nil) -> str_value
                    data.String(_) | data.Date(_) | data.Datetime(_) | data.Time(_) -> "\"" <> str_value <> "\""
                }
                    |> string_tree.from_string
            } |> string_tree.join(",")
        } |> string_tree.join("\n")
            |> string_tree.prepend_tree(string)
            |> string_tree.to_string
    }
    export_string(title <> ".csv", "text/csv", csv)
}
