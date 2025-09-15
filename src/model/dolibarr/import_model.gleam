import gleam/float
import gleam/pair
import decodex/relations
import given
import gleam/dict
import gleam/list
import model/dolibarr/manufacture/bill_of_materials_model.{BillOfMaterials, Draft, Item, Manufacture, Disassemble}
import util/csv
import gleam/result
import model/dolibarr/product/stock_model.{Stock, Insert}
import model/dolibarr/product/product_model.{Product, type Product}
import model/common_model.{Id}
import model/dolibarr/product/warehouse_model.{Warehouse, Open}
import gleam/option.{Some}
import decodex/numbers
import decodex/strings
import gleam/string
import gleam/dynamic/decode.{type Decoder}
import toolkit_util/numbers as util_numbers

pub opaque type ProductDTO
{
	ProductDTO(
		ref: String,
		label: String,
		manufacturable: Bool,
		ref_warehouse: String,
		initial_stock: Float,
		initial_stock_cost: Float,
		unit_price: Float,
	)
}

pub opaque type BOMItemDTO
{
	BOMItemDTO(
		ref_product_dto: String,
		quantity: Float,
	)
}

pub opaque type BillOfMaterialsDTO
{
    BillOfMaterialsDTO(
        ref: String,
        label: String,
        type_: bill_of_materials_model.Type,
        ref_product_dto: String,
        quantity: Float,
        items: List(BOMItemDTO),
    )
}

pub fn get_ref(model: ProductDTO)
{ model.ref }

pub fn get_ref_warehouse(model: ProductDTO)
{ model.ref_warehouse }

pub fn get_ref_product(model: BillOfMaterialsDTO)
{ model.ref_product_dto }

pub fn compute_bom(model: BillOfMaterialsDTO, products: List(Product))
{
	let BillOfMaterialsDTO(ref:, label:, type_:, ref_product_dto:, quantity:, items:) = model

	let assert Ok(product) = list.find(products, fn(p) {p.ref == ref_product_dto})
	BillOfMaterials(
		id: Id(0),
		ref:,
		label:,
		type_:,
		id_product: product.id,
		status: Draft,
		quantity:,
		description:"",
		id_warehouse: product.fk_default_warehouse,
		items: {
			use BOMItemDTO(ref_product_dto:, quantity:) <- list.map(items)			
	
			let assert Ok(product) = list.find(products, fn(p) {p.ref == ref_product_dto})
			Item(
				id_product: product.id,
				quantity:,
				quantity_frozen: False,
				stock_change_disable: False,
				manufacturing_efficiency: 1.
			)
		}
	)
}

pub fn compute_stock(model: ProductDTO, id_product, id_warehouse)
{
	Stock(
		id: Id(0),
		id_product:,
		id_warehouse:,
		quantity: model.initial_stock,
		price: Some(model.initial_stock_cost /. model.initial_stock),
		lot: model.ref,
		action: Insert
	)
}

pub fn compute_warehouse(model: ProductDTO)
{
	Warehouse(
		id: Id(0),
		ref: model.ref_warehouse,
		description: "",
		location: model.ref_warehouse,
		status: Open,
		id_country: Id(1)
	)
}

pub fn compute_product(model: ProductDTO, id_warehouse)
{
	let ProductDTO(ref:, label:, manufacturable:, ref_warehouse:_, initial_stock:_, initial_stock_cost:_, unit_price:) = model

	Product(
		id: Id(0),
		ref:,
		label:,
		description: "",
		price: unit_price,
		status: True,
		status_buy: True,
		finished: manufacturable,
		fk_default_warehouse: id_warehouse,
	)
}

pub fn decode_form(form)
{
	use product_dtos <- result.try(
		csv.decode_file_at(["file2"], form, product_dto_csv_decoder())
	)
	// (produit_ref, entrepot) should be unique
	let grouped_by_product_and_warehouse = {
		use product_dto <- list.group(product_dtos)
		#(product_dto.ref, product_dto.ref_warehouse)
	} |> dict.to_list
	use _ <- given.error({
		use #(_, products) <- list.find(grouped_by_product_and_warehouse)
		list.length(products) > 1
	}, fn(e) { echo e Error([decode.DecodeError(
		expected: "Distinct product ref per warehouse",
		found: "Multiple product ref in one warehouse",
		path: ["product_ref,warehouse"]
	)]) })
	
	// 1 product cannot have 2 different product_type
	let grouped_by_product_then_manufacturable = {
		use #(ref, rows) <- list.map(list.group(product_dtos, fn(p) {p.ref})
			|> dict.to_list)
		#(ref, list.group(rows, fn(row) {row.manufacturable}) |> dict.to_list)
	}
	use _ <- given.error({
		use #(_, types) <- list.find(grouped_by_product_then_manufacturable)
		list.length(types) > 1
	}, fn(e) { echo e Error([decode.DecodeError(
		expected: "Product with consistant type",
		found: "Same product having different types",
		path: ["product_ref,warehouse"]
	)]) })


	use boms <- result.try(
		csv.decode_file_at(["file1"], form, bom_dto_csv_decoder(list.map(product_dtos, compute_product(_, Id(0)))))
	)

	let boms_grouped_by_ref = list.group(boms, fn(p) {p.ref})
			|> dict.to_list

	use _ <- given.error({
		use #(_, boms) <- list.find(boms_grouped_by_ref)
		list.length(boms) > 1
	}, fn(e) { echo e Error([decode.DecodeError(
		expected: "Unique Bom",
		found: "Duplicate BOM ref",
		path: ["product_ref,warehouse"]
	)]) })
	Ok(#(product_dtos, boms))
}

fn composition_decoder(products: List(Product))
{
	use composition <- decode.then(decode.string)
	let bom_items = {
		use product_n_quantity <- list.try_map(composition |> string.trim |> string.split("+"))
		let product_n_quantity_split = product_n_quantity
			|> string.trim
			|> string.slice(1, string.length(product_n_quantity) - 2)
			|> string.split_once(",")
		use #(product_ref, quantity) <- given.ok(
			product_n_quantity_split,
			fn(_) {Error(product_n_quantity)}
		)
		let product_ref = product_ref |> string.trim
		let quantity = quantity |> string.trim
		let quantity = case quantity |> string.ends_with(".")
		{
			True -> quantity <> "0"
			False -> quantity
		}
	
		case
			products |> list.find(fn(product) {product.ref == product_ref}),
			util_numbers.parse(quantity)
			{
			Ok(product), Ok(quantity) -> #(
				product.ref,
				quantity,
			) |> Ok
			Error(_), _ -> Error("Unknown product: " <> product_ref)
			_, Error(_) -> Error("Invalid quantity: " <> quantity)
		}
	}
	case bom_items
	{
		Ok(items) -> decode.success({
			use #(ref_product_dto, quantities) <- list.map(
				list.group(items, pair.first) |> dict.to_list
			)
			let quantity = float.sum(quantities |> list.map(pair.second))
			BOMItemDTO(ref_product_dto:, quantity:)
		})
		Error(e) -> {
			echo e
			decode.failure([], "Pair (product_ref, quantity), got: " <> e)
		}
	}
}

fn bom_dto_csv_decoder(products: List(Product)) -> decode.Decoder(BillOfMaterialsDTO)
{
	use ref <- decode.field("bom_numero", decode.string
		|> decode.map(string.trim)
		|> decode.then(strings.non_empty)
	)

	use label <- decode.field("bom_libelle", decode.string
		|> decode.map(string.trim)
		|> decode.then(strings.non_empty)
	)

	use type_ <- decode.field("bom_type", {
		use type_ <- decode.then(decode.string)
		case type_ |> string.trim |> string.lowercase
		{
			"fabrication" -> decode.success(Manufacture)
			_ -> decode.success(Disassemble)
		}
	})

	use quantity <- decode.field("bom_qte", numbers.decoder())

	use product <- decode.field("bom_produit", decode.string
		|> decode.then(relations.map_exists(
			products,
			product_model.new(),
			fn(product: Product) {product.ref},
		)))
	let product = product.value

	use items <- decode.field("bom_composition", composition_decoder(products))

	let model = BillOfMaterialsDTO(
		ref:, label:, type_:, ref_product_dto: product.ref, quantity:, items:
	)

	use <- given.that(
		!product_model.is_manufacturable(product),
		fn() {decode.failure(model, "Cannot create a bom for a raw product")}
	)
	decode.success(model)
}

fn product_type_decoder()
{
	use product_type <- decode.then(decode.string)
	case product_type |> string.trim |> string.lowercase
	{
		"mp" -> decode.success( False )
		"pf" -> decode.success( True )
		_ -> decode.failure(False, "Product Type")
	}
}

fn product_dto_csv_decoder() -> Decoder(ProductDTO)
{
	use ref <- decode.field("produit_ref", decode.string
		|> decode.map(string.trim)
		|> decode.then(strings.non_empty)
	)
	use label <- decode.field("produit_nom", decode.string
		|> decode.map(string.trim)
		|> decode.then(strings.non_empty)
	)
	
	// + produit_type should be either 'Matière première' or 'Produit manufacturé'
	use manufacturable <- decode.field("produit_type", product_type_decoder())
	use ref_warehouse <- decode.field("entrepot", decode.string
		|> decode.map(string.trim)
		|> decode.then(strings.non_empty)
	)
	use initial_stock <- decode.field("stock_initial", numbers.decoder())
	use initial_stock_cost <- decode.field("valeur_stock_initial", numbers.decoder())

	// + prix_vente may be empty
	// + ?? each product must have a stock_initial and valeur_stock_initial or a prix_vente
	use unit_price <- decode.optional_field("prix_vente", 0., strings.decode_optional(numbers.decoder()) |> decode.map(option.unwrap(_, 0.)))

	let dto = ProductDTO(ref:, label:, manufacturable:, ref_warehouse:, initial_stock:, initial_stock_cost:, unit_price:)

	use <- given.that(initial_stock <. 0., fn() {decode.failure(dto, "'stock_initial' cannot be negative")})
	use <- given.that(initial_stock_cost <. 0., fn() {decode.failure(dto, "'valeur_stock_initial' cannot be negative")})
	use <- given.that(unit_price <. 0., fn() {decode.failure(dto, "'prix_vente' cannot be negative")})

	case initial_stock_cost == 0. && unit_price == 0.
	{
		True -> decode.failure(dto, "Either 'valeur_stock_initial' or 'prix_vente' should be set")
		False -> decode.success(dto)
}	}
	
