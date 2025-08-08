import toolkit_util/data.{type Data}
import view/components/stock_asap

@external(javascript, "../html2pdf_ffi.mjs", "generateTable")
pub fn generate_table(title: String, data: List(List(#(String, Data(stock_asap.Data))))) -> Nil