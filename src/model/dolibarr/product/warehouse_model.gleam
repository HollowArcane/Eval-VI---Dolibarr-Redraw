import view/components/bs5
import gleam/int
import gleam/dict
import model/common_model.{Id}
import gleam/list
import decodex/relations
import model/dolibarr/constant/country_model.{type Country}
import decodex/strings
import gleam/string
import decodex/numbers
import view/components/stock_asap
import toolkit_util/data
import gleam/json
import gleam/dynamic/decode

pub type Status
{
	Closed
	Open
}

fn status_to_json(status: Status) -> json.Json
{
	case status
	{
		Closed -> json.string("0")
		Open -> json.string("1")
	}
}

fn status_decoder() -> decode.Decoder(Status)
{
	use variant <- decode.then(decode.string)
	case variant
	{
		"0" -> decode.success(Closed)
		"1" -> decode.success(Open)
		_ -> decode.failure(Closed, "Status")
	}
}

pub type Warehouse
{
    Warehouse(
        id: common_model.Id(Warehouse),
        ref: String,
        description: String,
        location: String,
	status: Status,
        id_country: common_model.Id(Country),
    )
}

pub fn new()
{ Warehouse(Id(0), "", "", "", Closed, Id(0)) }

pub fn options(warehouses: List(Warehouse))
{
    use warehouse <- list.map(warehouses)
    #(int.to_string(warehouse.id.value), warehouse.location)
}

pub fn keyed(warehouses: List(Warehouse))
{
    {
        use warehouse <- list.map(warehouses)
        #(warehouse.id, warehouse)
    } |> dict.from_list
}


pub fn to_json(warehouse: Warehouse) -> json.Json
{
    let Warehouse(id:, ref:, description:, location:, id_country:, status:) = warehouse
    json.object([
        #("id", json.int(id.value)),
        #("label", json.string(ref)),
        #("description", json.string(description)),
        #("lieu", json.string(location)),
	#("statut", status_to_json(status)),
        #("country_id", json.int(id_country.value)),
    ])
}

pub fn decoder() -> decode.Decoder(Warehouse)
{
    use id <- decode.field("id", numbers.int_decoder() |> decode.map(Id))
    use ref <- decode.field("ref", decode.string)
    use description <- decode.field("description", decode.string)
    use location <- decode.field("lieu", decode.string)
	use status <- decode.field("statut", status_decoder())
    use id_country <- decode.field("country_id", numbers.int_decoder() |> decode.map(Id))
    decode.success(Warehouse(id:, ref:, description:, location:, status:, id_country:))
}

pub fn form_decoder(countries: List(Country)) -> decode.Decoder(Warehouse)
{
    echo list.length(countries)
    let id = Id(0)
    use ref <- decode.field("ref", decode.string
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty))
        
    use description <- decode.field("description", decode.string
        |> decode.map(string.trim))

    use location <- decode.field("location", decode.string
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty))
        
    use id_country <- decode.field("id_country", numbers.int_decoder()
        |> decode.map(Id)
        |> decode.then(relations.exists(countries |> list.map(fn(country) {country.id}))))
	let status = Open
    let id_country = id_country.value
    decode.success(Warehouse(id:, ref:, description:, location:, status:, id_country:))
}

pub fn csv_decoder(countries: List(Country)) -> decode.Decoder(Warehouse)
{
    let id = Id(0)
    use ref <- decode.field("ref", decode.string
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty))
        
    use description <- decode.optional_field("description", "", decode.string
        |> decode.map(string.trim))

    use location <- decode.field("location", decode.string
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty))

    use id_country <- decode.field("id_country", numbers.int_decoder()
        |> decode.map(Id)
        |> decode.then(relations.exists(countries |> list.map(fn(country) {country.id}))))
	let status = Open
    let id_country = id_country.value
    decode.success(Warehouse(id:, ref:, description:, location:, status:, id_country:))
}

pub fn format_view(model: Warehouse)
{
	[
		#("", data.Other(stock_asap.BtnExportPDF(model))),
		#("", data.Other(stock_asap.BtnDelete(model))),
		#("Réference", model.ref |> data.String),
		#("Lieu", model.location |> data.String),
		#("Description", model.description |> stock_asap.HTML |> data.Other),
		#("Statut", data.Other(case model.status
		{
			Closed -> stock_asap.Badge(text: "Fermé", variant: bs5.secondary)
			Open -> stock_asap.Badge(text: "Ouvert", variant: bs5.success)
		}))
	]
}

pub fn format_csv(model: Warehouse)
{
	[
		#("id", model.id.value |> data.Int),
		#("ref", model.ref |> data.String),
		#("description", model.description |> data.String),
		#("location", model.location |> data.String),
		#("id_country", model.id_country.value |> data.Int)
	]
}
