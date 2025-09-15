import model/dolibarr/product/product_model
import service/dolibarr/product/product_service
import given
import gleam/float
import model/dolibarr/product/stock_model.{Stock, Insert, Remove}
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleam/dynamic
import service/dolibarr/product/stock_service
import model/common_model.{type Id, Id}
import gleam/dynamic/decode
import gleam/int
import model/dolibarr/manufacture/manufacturing_order_model.{type ManufacturingOrder, Validated, ManufacturingOrder, Consumed, type Item, ToProduce, ToConsume, Produced, Item}
import gleam/javascript/promise
import util/api_request.{ApiError}
import gleam/result
import service/common_service
import service/dolibarr_service

pub fn fetch(token, at page, where _filter: Nil)
{
    dolibarr_service.list(token, ["mos"], manufacturing_order_model.decoder(), page, [])  
        |> promise.map(result.map(_, api_request.get_response_body)) 
}

pub fn fetch_one(token, id: Id(ManufacturingOrder))
{
    dolibarr_service.fetch_one(token,
        ["mos", int.to_string(id.value)],
        {
            use mo <- decode.then(manufacturing_order_model.decoder())
            decode.success(#(mo, mo.items))
        }
    ) |> promise.map(result.map(_, api_request.get_response_body)) 
}

pub fn fetch_all(token)
{
    token |> dolibarr_service.fetch_all(
        at: ["mos"],
        expect: manufacturing_order_model.decoder(), 
        page: 1,
        where: [],
        take: 1000
    ) |> promise.map(result.map(_, api_request.get_response_body)) 
}

pub fn import_(token, mos)
{ common_service.batch(mos, create(token, _)) }

fn compute_virtual_stock_from_mo_item(mo_item: Item, action)
{
	let Item(id_product:, id_warehouse:, quantity:, ..) = mo_item
	let quantity = quantity *. case action
	{
		Insert -> 1.
		Remove -> -1.
	}

	Stock(
		id: Id(0),
		id_product:,
		id_warehouse:,
		quantity:,
		price: None,
		lot: "Virtual Stock",
		action:,
	)
}

pub fn manufacture_all(token, mos)
{
	// PRECHECK TO VERIFY QUANTITY IS ENOUGH BEFORE PROCEEDING TO IRREVERSIBLE STOCK MOUVEMENTS
	use #(products, _) <- promise.try_await(
		product_service.fetch_all(token)
		|> promise.map(result.map_error(_, api_request.map_error(_, dynamic.classify)))
	)
	let products = product_model.keyed(products)
	use stocks_list <- promise.try_await(
		stock_service.fetch_all(token)
		|> promise.map(result.map_error(_, api_request.map_error(_, dynamic.classify)))
	)
	let #(_, mos) = {
		use stocks_list, mo <- list.map_fold(mos, stocks_list)
		let stocks = stock_model.group_by_product(stocks_list)
		
		let #(errors, stocks_list) = case mo |> manufacturing_order_model.to_production(stocks, products)
		{
			Error(errors) -> #(errors, stocks_list)
			Ok(#(consumed, produced)) -> {
				let stocks_list = {
					// loop throught consumed and produced
					use stocks_list, consumed <- list.fold(consumed, stocks_list)
					// push a vitual stock to the stocks_dict
					let new_stock = compute_virtual_stock_from_mo_item(consumed, Remove)
					[new_stock, ..stocks_list]
				}
				let stocks_list = {
					// loop throught consumed and produced
					use stocks_list, produced <- list.fold(produced, stocks_list)
					let new_stock = compute_virtual_stock_from_mo_item(produced, Insert)
					[new_stock, ..stocks_list]
				}
				#([], stocks_list)
			}
		}
		
		#(stocks_list, #(mo, errors))
	}
	
	
	use verdict <- promise.try_await({
		use #(mo, errors) <- common_service.sequential_batch(mos)
		use <- given.empty(errors, else_return: fn() {
			promise.resolve(Ok(#(mo, errors)))
		})

		use id <- promise.try_await(token |> create(mo))
		use #(mo, _) <- promise.try_await(token |> fetch_one(Id(id))
			|> promise.map(result.map_error(_, api_request.map_error(_, dynamic.classify)))
		)
		use mo <- promise.try_await(token |> update(mo, manufacturing_order_model.update_state)) 

		use mo <- promise.try_await(token |> update(mo, manufacturing_order_model.update_state)) 
		promise.resolve(Ok(#(mo, errors)))
	})
	promise.resolve(Ok(list.reverse(verdict)))
}


//fn create_line(token, id_parent: Id(ManufacturingOrder), item: manufacturing_order_model.Item)
//{ dolibarr_service.create(token, ["mos", int.to_string(id_parent.value), "line"], manufacturing_order_model.item_to_json(item))
//    |> promise.map(result.map(_, api_request.get_response_body)) }

pub fn create(token, mo: ManufacturingOrder)
{
    use id <- promise.try_await(
        dolibarr_service.create(token, ["mos"], manufacturing_order_model.to_json(mo))
            |> promise.map(result.map(_, api_request.get_response_body))
    )
	let mo = ManufacturingOrder(..mo,
		id: Id(id),
	)
	use _ <- promise.try_await({
		token |> dolibarr_service.query(mo.items
			|> list.map(manufacturing_order_model.items_to_sql(_, mo.id, None, None))
			|> string.join(";")
		)
	})
	//use _ <- promise.try_await(
	//	update(token, mo, fn(mo) { ManufacturingOrder(..mo,
	//		id: Id(id),
	//	) })
	//)
    promise.resolve(Ok(id))
    // let items = promise.await_list({
    //     use item <- list.map(mo.items)
    //     create_line(token, Id(id), item)
    // })
    // use items <- promise.await(items)
    // common_utils.promise(fn() {list.try_map(items, function.identity)})
}

pub fn delete(token, mo: ManufacturingOrder)
{ dolibarr_service.delete(token, ["mos", int.to_string(mo.id.value)])
    |> promise.map(result.map(_, api_request.get_response_body)) }

fn produce_or_consume(token, item: Item, id_mo: Id(ManufacturingOrder))
{
	// insert stock mouvement
	use id_stock <- promise.try_await(
		stock_service.create(token, Stock(
			id: Id(0),
			id_product: item.id_product,
			id_warehouse: item.id_warehouse,
			// THIS IS NOT GOOD, quantity AND action MAY NOT MATCH
			quantity: float.absolute_value(item.quantity),
			price: None,
			lot: "Manufacture " <> int.to_string(id_mo.value),
			action: case item.role
			{
				ToProduce | ToConsume -> Insert // this should not happen
				Consumed -> Remove
				Produced -> Insert
			}
		))
	)
	// call items_to_sql with stock_id and item_id
	let query = item |> manufacturing_order_model.items_to_sql(id_mo, Some(Id(id_stock)), Some(item.id))
	// call service.query
	token |> dolibarr_service.query(query)
}

fn process_production(token, mo)
{
	use #(products, _) <- promise.try_await(
		product_service.fetch_all(token)
		|> promise.map(result.map_error(_, api_request.map_error(_, dynamic.classify)))
	)
	let products = product_model.keyed(products)

	use stocks <- promise.try_await(
		stock_service.fetch_all(token)
		|> promise.map(result.map_error(_, api_request.map_error(_, dynamic.classify)))
	)
	let stocks = stock_model.group_by_product(stocks)
	use #(consumed, produced) <- promise.try_await(
		manufacturing_order_model.to_production(mo, stocks, products)
			|> result.map_error(string.inspect)
			|> result.map_error(ApiError)
			|> promise.resolve
	) 

	use _ <- promise.try_await(
		common_service.sequential_batch(consumed, produce_or_consume(token, _, mo.id))
	)
	common_service.sequential_batch(produced, produce_or_consume(token, _, mo.id))

	//let prod = mo |> manufacturing_order_model.to_production(stocks)
	//token |> dolibarr_service.create(
	//	at: ["mos", int.to_string(mo.id.value), "produceandconsumeall"],
	//	model: manufacturing_order_model.production_to_json(prod)
	//) |> promise.map(result.map(_, api_request.get_response_body))
}

pub fn update(token, mo: ManufacturingOrder, map)
{
	// before update, if state is validated: consume
	use _ <- promise.try_await(case mo.status
	{
		Validated -> token |> process_production(mo)
		_ -> promise.resolve(Ok([]))
	})
	let mo: ManufacturingOrder = map(mo)
	dolibarr_service.update(token, ["mos", int.to_string(mo.id.value)], manufacturing_order_model.to_json(mo), manufacturing_order_model.decoder())
	|> promise.map(result.map(_, api_request.get_response_body))
}
