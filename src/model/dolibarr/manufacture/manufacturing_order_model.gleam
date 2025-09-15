import toolkit_util/recursions.{End, Continue}
import util/sql
import util/timestamps
import given
import model/dolibarr/product/stock_model.{type Stock}
import decodex/bools
import view/components/bs5
import gleam/float
import gleam/list
import gleam/string
import gleam/int
import model/dolibarr/manufacture/bill_of_materials_model.{type BillOfMaterials}
import toolkit_util/calendar/time
import toolkit_util/bools as util_bools
import toolkit_util/calendar/date
import gleam/time/calendar.{TimeOfDay, Date} as gcalendar
import gleam/time/timestamp
import decodex/strings
import gleam/option.{None, type Option}
import gleam/result
import gleam/dict.{type Dict}
import view/components/stock_asap
import toolkit_util/data
import decodex/relations
import toolkit_util/calendar.{Calendar}
import model/dolibarr/product/warehouse_model.{type Warehouse}
import model/dolibarr/product/product_model.{type Product}
import model/common_model.{type Id, Id}
import gleam/json
import decodex/numbers
import gleam/dynamic/decode

//pub opaque type ProductionItem
//{
//	ProductionItem(
//		id_product: Id(Product),
//		id_warehouse: Id(Warehouse),
//		quantity: Float,
//	)
//}
//
//fn production_item_to_json(production_item: ProductionItem) -> json.Json 
//{
//	let ProductionItem(id_product:, id_warehouse:, quantity:) = production_item
//	json.object([
//		#("fk_product", json.int(id_product.value)),
//		#("fk_warehouse", json.int(id_warehouse.value)),
//		#("qty", json.float(float.to_precision(quantity, 2))),
//	])
//}
//
//pub opaque type Production
//{
//	Production(
//		label: String,
//		code: String,
//		to_consume: List(ProductionItem),
//		to_produce: List(ProductionItem),
//	)
//}
//
//pub fn production_to_json(production: Production) -> json.Json
//{
//	let Production(label:, code:, to_consume:, to_produce:) = production
//	json.object([
//		#("inventorylabel", json.string(label)),
//		#("inventorycode", json.string(code)),
//		#("arraytoconsume", json.array(to_consume, production_item_to_json)),
//		#("arraytoproduce", json.array(to_produce, production_item_to_json)),
//	])
//}

pub type Type
{
    Manufacture
    Disassemble
}

fn type_to_json(type_: Type) -> json.Json
{ type_to_int(type_) |> json.int }

fn type_to_int(type_: Type) -> Int
{
    case type_
    {
        Manufacture -> 0
        Disassemble -> 1
    }
}

fn type_decoder() -> decode.Decoder(Type)
{
    use variant <- decode.then(numbers.int_decoder())
    case variant
    {
        0 -> decode.success(Manufacture)
        1 -> decode.success(Disassemble)
        _ -> decode.failure(Manufacture, "Type")
    }
}

pub type Status
{
	Draft
	Validated
	InProgress
	Finished
}

fn status_to_json(status: Status) -> json.Json
{
	case status
	{
		Draft -> json.int(0)
		Validated -> json.int(1)
		InProgress -> json.int(2)
		Finished -> json.int(3)
	}
}

fn status_decoder() -> decode.Decoder(Status)
{
	use variant <- decode.then(decode.int)
	case variant {
		0 -> decode.success(Draft)
		1 -> decode.success(Validated)
		2 -> decode.success(InProgress)
		3 -> decode.success(Finished)
		_ -> decode.failure(Draft, "Status")
	}
}

pub type ItemRole
{
	ToProduce
	ToConsume
	Produced
	Consumed
}

pub type Item
{
    Item(
	id: Id(Item),
        id_product: Id(Product),
	id_warehouse: Id(Warehouse),
        quantity: Float,
        quantity_frozen: Bool,
        stock_change_disable: Bool,
	role: ItemRole,
        manufacturing_efficiency: Float,
	id_bom: Id(bill_of_materials_model.BillOfMaterials),
    )
}

pub fn item_to_json(item: Item) -> json.Json
{
    let Item(id:_, id_product:, quantity:, quantity_frozen:_, stock_change_disable:_, manufacturing_efficiency:_, id_bom:_, id_warehouse:, role:_) = item
    json.object([
        #("fk_product", id_product.value |> json.int),
        #("fk_warehouse", id_warehouse.value |> json.int),
        #("qty", json.float(quantity)),
        #("description", json.string("")),
//	#("qty_frozen", json.bool(quantity_frozen)),
//	#("disable_stock_change", json.bool(stock_change_disable)),
//	#("efficiency", json.float(manufacturing_efficiency)),
//	#("fk_bom", json.int(id_bom.value)),
    ])
}

fn item_role_decoder() -> decode.Decoder(ItemRole)
{
	use variant <- decode.then(decode.string)
	case variant |> string.trim |> string.lowercase
	{
		"toproduce" -> decode.success(ToProduce)
		"toconsume" -> decode.success(ToConsume)
		"consumed" -> decode.success(Consumed)
		"produced" -> decode.success(Produced)
		_ -> decode.failure(ToProduce, "ItemRole")
	}
}

fn item_decoder() 
{
	use id <- decode.field("id", decode.int |> decode.map(Id))
    use id_product <- decode.field("fk_product", decode.int |> decode.map(Id))
    use id_bom <- decode.optional_field("fk_bom", Id(0), decode.optional(decode.int |> decode.map(Id)) |> decode.map(option.unwrap(_, Id(0))))
    use quantity <- decode.field("qty", decode.float)
	use quantity_frozen <- decode.optional_field("qty_frozen", False, decode.optional(bools.decode_int()) |> decode.map(option.unwrap(_, False)))
    use id_warehouse <- decode.optional_field("fk_warehouse", Id(0), decode.optional( decode.int |> decode.map(Id) ) |> decode.map(option.unwrap(_, Id(0))))
	use stock_change_disable <- decode.optional_field("disable_stock_change", False, decode.optional(bools.decode_int()) |> decode.map(option.unwrap(_, False)))
	use manufacturing_efficiency <- decode.optional_field("efficiency", 1., decode.optional(decode.float) |> decode.map(option.unwrap(_, 1.)))

	use role <- decode.field("role", item_role_decoder())

    decode.success(Item(id:, id_product:, quantity:, quantity_frozen:, stock_change_disable:, manufacturing_efficiency:, id_bom:, id_warehouse:, role:))
}

pub type ManufacturingOrder
{
    ManufacturingOrder(
        id: Id(ManufacturingOrder),
        ref: String,
        mrptype: Type,
        id_product: Id(Product),
	status: Status,
        quantity: Float,
        label: String,
        id_warehouse: Id(Warehouse),
        date_start: option.Option(calendar.Calendar),
        date_end: option.Option(calendar.Calendar),
        items: List(Item)
    )
}

pub fn new()
{ ManufacturingOrder(Id(0), "", Manufacture, Id(0), Draft, 0., "", Id(0), None, None, []) }

pub fn update_state(model: ManufacturingOrder)
{
	case model.status
	{
		Draft -> ManufacturingOrder(..model,
			status: Validated,
		)
		Finished -> model
		InProgress -> ManufacturingOrder(..model,
			status: Finished,
		)
		Validated -> ManufacturingOrder(..model,
			status: Finished,
		)
	}
}

pub fn to_production(manufacturing_order: ManufacturingOrder, stocks: Dict(Id(Product), List(Stock)), products: Dict(Id(Product), Product)) 
{
	let ManufacturingOrder(id_product:, quantity:, label:_, id_warehouse:, items:, ..) = manufacturing_order
	let to_consume = {
		// foreach item
		use item <- list.map(items)
		// which is to_consume
		use <- given.that(item.role != ToConsume, fn() {Ok( [] )})
		let Item(id:_, id_product:_, id_warehouse:_, quantity:_, quantity_frozen:, stock_change_disable:, role:_, manufacturing_efficiency:, id_bom:) = item

		// scroll through stocks
		use #(stocks, items, quantity_left) <- recursions.start(#(
			stocks |> dict.get(item.id_product)
				|> result.unwrap([]),
			[],
			item.quantity,
		))
		// if stock is available, create a new ProductionItem for that and decrease needed quantity util needed quantity <= 0
		case quantity_left <=. 0., stocks
		{
			True, _ -> End(Ok(items)) // stock computation is done

			False, [] -> End(Error("" <> products
				|> dict.get(item.id_product)
				|> result.map(fn(product) {
					product.ref <> " - " <> product.label
				})
				|> result.unwrap("")
			<> " missing " <> {quantity_left |> float.to_precision(2) |> float.to_string()} )) // no enough stock

			False, [stock, ..stocks] if stock.quantity <=. 0.
				-> Continue(#(stocks, items, quantity_left)) // skip stock withdrawals

			False, [stock, ..stocks] -> {
				let quantity = case quantity_left >. stock.quantity
				{
					True -> stock.quantity
					False -> quantity_left
				}
				let item = Item(
					id_product: item.id_product,
					id_warehouse: stock.id_warehouse,
					quantity:,
					id: Id(0),
					quantity_frozen:,
					stock_change_disable:,
					role: Consumed,
					manufacturing_efficiency:,
					id_bom:
				)
				Continue(#(
					stocks,
					[item, ..items],
					quantity_left -. quantity,
				))
			}
		}
	}
	use to_consume <- given.all_ok(in: to_consume, else_return: fn(_, errors) {Error(errors)})
	let to_consume = list.flatten(to_consume)
	let to_produce = [
		Item(
			id_product:,
			id_warehouse:,
			quantity:,
			id: Id(0),
			quantity_frozen: False,
			stock_change_disable: False,
			role: Produced,
			manufacturing_efficiency: 1.,
			id_bom: Id(0),
		)
	]
	Ok(#(to_consume, to_produce))

 	//Production(
	//	label: "Production " <> label,
	//	code: "PRODUCTION YYYY-MM-DD",
	//	to_consume: {
	//		// foreach item
	//		use item <- list.flat_map(items)
	//		use <- resource.lazy_defer(pair.first)
	//		// scroll through stocks
	//		use #(items, quantity_left), stock <- list.fold(
	//			stocks |> dict.get(item.id_product)
	//				|> result.unwrap([]),
	//			#([], item.quantity)
	//		)
	//		// if stock is available, create a new ProductionItem for that and decrease needed quantity util needed quantity <= 0
	//		use <- given.that(
	//			stock.quantity <=. 0. ||
	//			quantity_left <=. 0.,
	//			return: fn() { #(items, quantity_left) }
	//		)
	//		let quantity = case quantity_left >. stock.quantity
	//		{
	//			True -> stock.quantity
	//			False -> quantity_left
	//		}
	//		let item = ProductionItem(
	//			id_product: item.id_product,
	//			id_warehouse: stock.id_warehouse,
	//			quantity:,
	//		)
	//		#([item, ..items], quantity_left -. quantity)
	//	}, to_produce: [
	//		ProductionItem(
	//			id_product:,
	//			id_warehouse:,
	//			quantity:,
	//		)
	//	]
	//)
}

pub fn to_json(manufacturing_order: ManufacturingOrder) -> json.Json
{
    let ManufacturingOrder(id:, status:, items:, ref:, mrptype:, id_product:, quantity:, label:, id_warehouse:, date_start:, date_end:) = manufacturing_order
    json.object([
        #("status", status_to_json(status)),
        #("ref", json.string(ref)),
        #("mrptype", type_to_json(mrptype)),
        #("fk_product", json.int(id_product.value)),
        #("qty", json.float(quantity)),
        #("label", json.string(label)),
        #("fk_warehouse", json.int(id_warehouse.value)),
        #("date_start_planned", json.nullable(date_start |> option.map(calendar.to_string), json.string)),
        #("date_end_planned", json.nullable(date_end |> option.map(calendar.to_string), json.string)),
        ..case id == Id(0) // do not add lines when model is newly created
	{
		True -> []
		False -> [#("lines", json.array(items, item_to_json))]
	},
    ])
}
		
fn decode_date()
{
    decode.one_of(
        calendar.string_decoder(), [
        {
            use timestamp_millis <- decode.then(decode.int)
            let #(
                Date(year:, month:, day:),
                TimeOfDay(hours:, minutes:, seconds:, nanoseconds:)
            ) = timestamp.from_unix_seconds(timestamp_millis)
                |> timestamp.to_calendar(gcalendar.utc_offset)
            
            decode.success(Calendar(
                date.new(year, gcalendar.month_to_int(month), day),
                time.new(hours, minutes, seconds, nanoseconds / 1000)
            ))
        }
    ])
}

pub fn decoder() -> decode.Decoder(ManufacturingOrder)
{
    use id <- decode.field("id", decode.int |> decode.map(Id))
    use ref <- decode.field("ref", decode.string)
    use mrptype <- decode.field("mrptype", type_decoder())
    use id_product <- decode.field("fk_product", decode.int |> decode.map(Id))
    use quantity <- decode.field("qty", decode.float)
    use label <- decode.field("label", decode.optional(decode.string) |> decode.map(option.unwrap(_, "")))
	use status <- decode.field("status", status_decoder())
    use id_warehouse <- decode.field("fk_warehouse", decode.optional(decode.int) |> decode.map(option.map(_, Id)) |> decode.map(option.unwrap(_, Id(0))))
    use date_start <- decode.field("date_start_planned", strings.decode_optional(decode_date()))
    use date_end <- decode.field("date_end_planned", strings.decode_optional(decode_date()))
    use items <- decode.optional_field("lines", [], decode.list(item_decoder()))
	let items = {
		use items, item <- list.fold(items, [])
		case item.role
		{
			ToConsume | ToProduce -> [item, ..items]
			Consumed | Produced -> items
		}
	}

    decode.success(ManufacturingOrder(id:, ref:, items:, status:, mrptype:, id_product:, quantity:, label:, id_warehouse:, date_start:, date_end:))
}

pub fn form_decoder(boms: List(BillOfMaterials)) -> decode.Decoder(ManufacturingOrder)
{
    let id = Id(0)
	let status = Draft
//    use ref <- decode.field("ref", decode.string
//		|> decode.map(string.trim)
//		|> decode.then(strings.non_empty)
//	)
    use bom <- decode.field("id_bill_of_materials", numbers.int_decoder()
        |> decode.map(fn(id) {Id(id)})
        |> decode.then(relations.map_exists(boms, bill_of_materials_model.new(), fn(bom) {bom.id})))
    let mrptype = case bom.value.type_
    {
        bill_of_materials_model.Disassemble -> Disassemble
        bill_of_materials_model.Manufacture -> Manufacture
    }
    let id_product = bom.value.id_product
    use bom_quantity <- decode.field("quantity", numbers.decoder())
	let quantity = bom_quantity
	let ref = bom.value.ref <> "_" <> {timestamps.now() |> calendar.to_string}
	let label = ref
//    use label <- decode.field("label", decode.string
//		|> decode.map(string.trim)
//		|> decode.then(strings.non_empty)
//	)
    let id_warehouse = bom.value.id_warehouse
    // use date_start <- decode.field("date_start", decode_date() |> decode.map(Some))

    // use date_end <- decode.field("date_end", decode_date() |> decode.map(Some))
	let date_start = None
	let date_end = None

	let items = {
		use bill_of_materials_model.Item(id_product:, quantity:, quantity_frozen:, stock_change_disable:, manufacturing_efficiency:)
			<- list.map(bom.value.items)

		let quantity = bom_quantity *. quantity /. bom.value.quantity // item_quantity per unit_bom  times  bom_quantity
		Item(id: Id(0), id_product:, quantity:, role: ToConsume, quantity_frozen:, stock_change_disable:, manufacturing_efficiency:, id_bom: bom.value.id, id_warehouse:)
		
	}
    decode.success(ManufacturingOrder(id:, status:, items:, ref:, mrptype:, id_product:, quantity:, label:, id_warehouse:, date_start:, date_end:))
}

pub fn format_csv(model: ManufacturingOrder)
{
	[
		#("ref", model.ref |> data.String),
		#("mrptype", model.mrptype |> type_to_int |> data.Int),
		#("id_product", model.id_product.value |> data.Int),
		#("quantity", model.quantity |> data.Float),
		#("label", model.label |> data.String),
		#("id_warehouse", model.id_warehouse.value |> data.Int),
		#("date_start", model.date_start |> option.map(data.Datetime) |> option.unwrap(data.String(""))),
		#("date_end", model.date_end |> option.map(data.Datetime) |> option.unwrap(data.String("")))
	]
}

pub fn format_view(model: ManufacturingOrder, products: Dict(Id(Product), Product), warehouses: Dict(Id(Warehouse), Warehouse))
{
	let btn_update = case model.status
	{
		Draft -> data.Other(stock_asap.BtnUpdate("Valider", "fa fa-check", model, update_state))
		Finished -> data.String("")
		InProgress -> data.Other(stock_asap.BtnUpdate("Produire", "fa fa-rotate", model, update_state))

		Validated -> data.Other(stock_asap.BtnUpdate("Produire", "fa fa-rotate", model, update_state))

	}
	[
		#("", data.Other(stock_asap.BtnExportPDF(model))),
		#("", btn_update),
		#("", data.Other(stock_asap.BtnDelete(model))),
		#("", data.Other(stock_asap.BtnGoto(path: "/manufacturing-order/" <> model.id.value |> int.to_string))),
		#("Libellé", model.label |> data.String),
		#("Type", case model.mrptype
			{
			Disassemble -> "Déssassemblage"
			Manufacture -> "Fabrication"
		} |> data.String),
		#("Produit", products |> dict.get(model.id_product) |> result.map(fn(product) {product.ref <> " - " <> product.label}) |> result.unwrap("") |> data.String),
		#("Quantité", model.quantity |> data.Float),
		#("Entrepôt", warehouses |> dict.get(model.id_warehouse) |> result.map(fn(warehouse) {warehouse.location}) |> result.unwrap("") |> data.String),
		//#("Date de Début", model.date_start |> option.map(data.Datetime) |> option.unwrap(data.String(""))),
		//#("Date de Début", model.date_end |> option.map(data.Datetime) |> option.unwrap(data.String(""))),
		#("Statut", case model.status
		{
			Draft -> stock_asap.Badge(text: "Brouillon", variant: bs5.secondary)
			Finished -> stock_asap.Badge(text: "Terminé", variant: bs5.secondary_success)
			InProgress -> stock_asap.Badge(text: "En Cours", variant: bs5.success)
			Validated -> stock_asap.Badge(text: "Validé", variant: bs5.info)
		} |> data.Other),
	]
}

pub fn format_card(model: ManufacturingOrder, products: Dict(Id(Product), Product), warehouses: Dict(Id(Warehouse), Warehouse))
{
	[
		#("Libellé", model.label |> data.String),
		#("Type", case model.mrptype
        {
            Disassemble -> "Déssassemblage"
            Manufacture -> "Fabrication"
        } |> data.String),
		#("Produit", products |> dict.get(model.id_product) |> result.map(fn(product) {product.ref <> " - " <> product.label}) |> result.unwrap("") |> data.String),
		#("Quantité", model.quantity |> data.Float),
		#("Entrepôt", warehouses |> dict.get(model.id_warehouse) |> result.map(fn(warehouse) {warehouse.location}) |> result.unwrap("") |> data.String),
		//#("Date de Début", model.date_start |> option.map(data.Datetime) |> option.unwrap(data.String(""))),
		//#("Date de Fin", model.date_end |> option.map(data.Datetime) |> option.unwrap(data.String("")))
	]
}

pub fn format_verdict(model: #(ManufacturingOrder, List(String)), products: Dict(Id(Product), Product), warehouses: Dict(Id(Warehouse), Warehouse))
{
	let #(model, errors) = model
	[
		#("Statut", case errors
		{
			[] -> data.Other(stock_asap.Badge(variant: bs5.success, text: "OK"))
			_ -> data.Other(stock_asap.HTML(
				"<ul class=\"text-danger\"><li>" <> errors |> string.join("</li> <li>") <> "</li></ul>"
			)) 
		}),
		#("Libellé", model.label |> data.String),
		#("Type", case model.mrptype
        {
            Disassemble -> "Déssassemblage"
            Manufacture -> "Fabrication"
        } |> data.String),
		#("Produit", products |> dict.get(model.id_product) |> result.map(fn(product) {product.ref <> " - " <> product.label}) |> result.unwrap("") |> data.String),
		#("Quantité", model.quantity |> data.Float),
		#("Entrepôt", warehouses |> dict.get(model.id_warehouse) |> result.map(fn(warehouse) {warehouse.location}) |> result.unwrap("") |> data.String),
		//#("Date de Début", model.date_start |> option.map(data.Datetime) |> option.unwrap(data.String(""))),
		//#("Date de Fin", model.date_end |> option.map(data.Datetime) |> option.unwrap(data.String("")))
	]
}

pub fn format_item_view(model: Item, products: Dict(Id(Product), Product))
{
	[
		#("Produit", products |> dict.get(model.id_product) |> result.map(fn(product) {product.ref <> " - " <> product.label}) |> result.unwrap("") |> data.String),
		#("Quantité", model.quantity |> data.Float),
		#("Role", case model.role
		{
			ToConsume -> "Consommation" |> stock_asap.Badge(bs5.info)
			ToProduce -> "Production" |> stock_asap.Badge(bs5.success)
			Consumed -> "Consommé" |> stock_asap.Badge(bs5.info)
  			Produced -> "Produit" |> stock_asap.Badge(bs5.success)
		} |> data.Other),
	]
}

pub fn items_to_sql(item: Item, id_mo: Id(ManufacturingOrder), id_stock: Option(Id(Stock)), id_source: Option(Id(Item)))
{
	let now = timestamps.now()
	sql.insert("llx_mrp_production", [
		#("fk_mo", data.Int(id_mo.value)),
		#("position", data.Int(1)),
		#("fk_product", data.Int(item.id_product.value)),
		#("qty", data.Float(item.quantity)),
		#("role", case item.role
		{
			ToProduce -> "toproduce"
			ToConsume -> "toconsume"
			Consumed -> "consumed"
			Produced -> "produced"
		} |> data.String),
		#("date_creation", data.Datetime(now)),
		#("tms", data.Datetime(now)),
		#("fk_user_creat", data.Int(30)),
		#("qty_frozen", util_bools.check(item.quantity_frozen, 1, 0) |> data.Int),
		#("disable_stock_change", util_bools.check(item.stock_change_disable, 1, 0) |> data.Int),
		#("fk_stock_movement", {
			use id_stock <- option.map(id_stock)
			id_stock.value |> data.Int
		} |> option.unwrap(data.Other(Nil))),
		#("fk_mrp_production", {
			use id_source <- option.map(id_source)
			id_source.value |> data.Int
		} |> option.unwrap(data.Other(Nil))),
	])
}
