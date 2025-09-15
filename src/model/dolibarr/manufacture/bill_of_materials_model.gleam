import given
import toolkit_util/numbers as util_numbers
import view/components/bs5
import gleam/float
import decodex/bools
import gleam/int
import view/components/stock_asap
import gleam/option
import gleam/list
import decodex/relations
import gleam/result
import gleam/dict.{type Dict}
import toolkit_util/data
import decodex/numbers
import decodex/strings
import gleam/string
import gleam/json
import gleam/dynamic/decode
import model/dolibarr/product/warehouse_model.{type Warehouse}
import model/dolibarr/product/product_model.{type Product}
import model/common_model.{type Id, Id}

pub type Type
{
    Manufacture
    Disassemble
}

fn type_to_json(type_: Type) -> json.Json
{
    case type_
    {
        Manufacture -> json.string("0")
        Disassemble -> json.string("1")
    }
}

fn type_decoder() -> decode.Decoder(Type)
{
    use variant <- decode.then(numbers.int_decoder())
    case variant {
        0 -> decode.success(Manufacture)
        1 -> decode.success(Disassemble)
        _ -> decode.failure(Manufacture, "Type")
    }
}

pub type Status
{
	Draft
	Enabled
}

fn status_to_json(status: Status) -> json.Json
{
	case status
	{
		Draft -> json.int(0)
		Enabled -> json.int(1)
	}
}

fn status_decoder() -> decode.Decoder(Status)
{
	use variant <- decode.then(decode.int)
	case variant
	{
		0 -> decode.success(Draft)
		1 -> decode.success(Enabled)
		_ -> decode.failure(Draft, "Status")
	}
}

pub type Item
{
    Item(
        id_product: Id(Product),
        quantity: Float,
        quantity_frozen: Bool,
        stock_change_disable: Bool,
        manufacturing_efficiency: Float,
    )
}

pub fn item_to_json(item: Item) -> json.Json
{
    let Item(id_product:, quantity:, quantity_frozen:, stock_change_disable:, manufacturing_efficiency:) = item
    json.object([
        #("fk_product", id_product.value |> json.int),
        #("qty", json.float(quantity)),
        #("qty_frozen", json.bool(quantity_frozen)),
        #("disable_stock_change", json.bool(stock_change_disable)),
        #("efficiency", json.float(manufacturing_efficiency)),
    ])
}

fn item_decoder() -> decode.Decoder(Item)
{
    use id_product <- decode.field("fk_product", numbers.int_decoder() |> decode.map(Id))
    use quantity <- decode.field("qty", numbers.decoder())
    use quantity_frozen <- decode.field("qty_frozen", bools.decode_int())
    use stock_change_disable <- decode.field("disable_stock_change", bools.decode_int())
    use manufacturing_efficiency <- decode.field("efficiency", numbers.decoder())
    decode.success(Item(id_product:, quantity:, quantity_frozen:, stock_change_disable:, manufacturing_efficiency:))
}

pub type BillOfMaterials
{
    BillOfMaterials(
        id: Id(BillOfMaterials),
        ref: String,
        label: String,
        type_: Type,
        id_product: Id(Product),
	status: Status,
        quantity: Float,
        description: String,
        id_warehouse: Id(Warehouse),
        items: List(Item),
    )
}

pub fn new()
{ BillOfMaterials(Id(0), "", "", Manufacture, Id(0), Draft, 0., "", Id(0), items: []) }

pub fn options(boms: List(BillOfMaterials))
{
    use bom <- list.map(boms)
    #(bom.id.value |> int.to_string, bom.ref <> " - " <> bom.label)
}

pub fn keyed(boms: List(BillOfMaterials))
{
    {
        use bom <- list.map(boms)
        #(bom.id, bom)
    } |> dict.from_list
}

pub fn to_json(bill_of_materials: BillOfMaterials) -> json.Json
{
    let BillOfMaterials(id:, label:, type_:, id_product:, quantity:, description:, id_warehouse:, ref:, items:_, status:) = bill_of_materials
    json.object([
        #("id", id.value |> json.int),
        #("ref", json.string(ref)),
        #("label", json.string(label)),
	#("status", status_to_json(status)),
        #("bomtype", type_to_json(type_)),
        #("fk_product", id_product.value |> json.int),
        #("qty", json.float(quantity)),
        #("description", json.string(description)),
        #("fk_warehouse", id_warehouse.value |> json.int),
        // #("lines", json.array(items, item_to_json)),
    ])
}

pub fn decoder() -> decode.Decoder(BillOfMaterials)
{
    use id <- decode.field("id", numbers.int_decoder() |> decode.map(Id))
	use status <- decode.field("status", status_decoder())
    use ref <- decode.field("ref", decode.string)
    use label <- decode.field("label", decode.string)
    use type_ <- decode.field("bomtype", type_decoder())
    use id_product <- decode.field("fk_product", numbers.int_decoder() |> decode.map(Id))
    use quantity <- decode.field("qty", numbers.decoder())
    use description <- decode.field("description", decode.optional(decode.string)
        |> decode.map(option.unwrap(_, "")))
    use id_warehouse <- decode.field("fk_warehouse", decode.optional(numbers.int_decoder())
        |> decode.map(option.unwrap(_, 0))
        |> decode.map(Id))
    use items <- decode.optional_field("lines", [], decode.list(item_decoder()))
    decode.success(BillOfMaterials(id:, items:, ref:, status:, label:, type_:, id_product:, quantity:, description:, id_warehouse:))
}

pub fn form_decoder(items: List(Item), products: List(Product), warehouses: List(Warehouse)) -> decode.Decoder(BillOfMaterials)
{
    let id = Id(0)
    use ref <- decode.field("ref", decode.string
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty))
    use label <- decode.field("label", decode.string
        |> decode.map(string.trim)
        |> decode.then(strings.non_empty))
    use type_ <- decode.field("type", type_decoder())
    use id_product <- decode.field("id_product", numbers.int_decoder()
        |> decode.map(Id)
        |> decode.then(relations.exists(list.map(products, fn(product) {product.id}))))
    let id_product = id_product.value
    use quantity <- decode.field("quantity", numbers.decoder())
    use description <- decode.field("description", decode.string)
    use id_warehouse <- decode.field("id_warehouse", numbers.int_decoder()
        |> decode.map(Id)
        |> decode.then(relations.exists(list.map(warehouses, fn(warehouse) {warehouse.id}))))
	let status = Draft
    let id_warehouse = id_warehouse.value
    decode.success(BillOfMaterials(id:, ref:, label:, type_:, id_product:, quantity:, description:, id_warehouse:, items:, status:))
}

pub fn format_csv(model: BillOfMaterials)
{
	[
		#("ref", model.ref |> data.String),
		#("label", model.label |> data.String),
		#("type", case model.type_
        {
            Disassemble -> "1"
            Manufacture -> "0"
        } |> data.String),
		#("id_product", model.id_product.value |> data.Int),
		#("quantity", model.quantity |> data.Float),
		#("description", model.description |> data.String),
		#("id_warehouse", model.id_warehouse.value |> data.Int)
	]
}

pub fn format_view(model: BillOfMaterials, products: Dict(Id(Product), Product), warehouses: Dict(Id(Warehouse), Warehouse))
{
	[
        #("", data.Other(stock_asap.BtnExportPDF(model))),
        #("", data.Other(stock_asap.BtnDelete(model))),
        #("", data.Other(stock_asap.BtnGoto("/bill-of-materials/" <> model.id.value |> int.to_string))),
		#("Libellé", model.label |> data.String),
		#("Type", case model.type_
        {
            Disassemble -> "Déssassemblage"
            Manufacture -> "Fabrication"
        } |> data.String),
		#("Produit", products |> dict.get(model.id_product) |> result.map(fn(product) {product.ref <> " - " <> product.label}) |> result.unwrap("") |> data.String),
		#("Quantité", model.quantity |> data.Float),
		#("Description", model.description |> data.String),
		#("Entrepôt", warehouses |> dict.get(model.id_warehouse) |> result.map(fn(warehouse) {warehouse.ref <> " - " <> warehouse.location}) |> result.unwrap("") |> data.String),
		#("Statut", case model.status
		{
			Draft -> stock_asap.Badge(text: "Brouillon", variant: bs5.secondary)
			Enabled -> stock_asap.Badge(text: "Activé", variant: bs5.success)
		} |> data.Other),
	]
}

pub fn format_card(model: BillOfMaterials, products: Dict(Id(Product), Product), warehouses: Dict(Id(Warehouse), Warehouse))
{
	[
		#("Libellé", model.label |> data.String),
		#("Type", case model.type_
        {
            Disassemble -> "Déssassemblage"
            Manufacture -> "Fabrication"
        } |> data.String),
		#("Produit", products |> dict.get(model.id_product) |> result.map(fn(product) {product.ref <> " - " <> product.label}) |> result.unwrap("") |> data.String),
		#("Quantité", model.quantity |> data.Float),
		#("Description", model.description |> data.String),
		#("Entrepôt", warehouses |> dict.get(model.id_warehouse) |> result.map(fn(warehouse) {warehouse.ref <> " - " <> warehouse.location}) |> result.unwrap("") |> data.String),
		#("Statut", case model.status
		{
			Draft -> stock_asap.Badge(text: "Brouillon", variant: bs5.secondary)
			Enabled -> stock_asap.Badge(text: "Activé", variant: bs5.success)
		} |> data.Other),
	]
}

pub fn format_item_view(model: Item, products: Dict(Id(Product), Product))
{
	[
		#("Produit", products |> dict.get(model.id_product) |> result.map(fn(product) {product.ref <> " - " <> product.label}) |> result.unwrap("") |> data.String),
		#("Quantité", model.quantity |> data.Float),
		#("Quantité Fixe", model.quantity_frozen |> data.Bool),
		#("Stock Fixe", model.stock_change_disable |> data.Bool),
		#("Efficacité", {float.to_string(model.manufacturing_efficiency *. 100.) <> "%"} |> data.String)
	]
}
