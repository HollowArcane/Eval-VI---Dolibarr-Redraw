import service/dolibarr/manufacture/bills_of_materials_service
import service/dolibarr/product/stock_service
import service/dolibarr/product/product_service
import model/dolibarr/product/product_model.{type Product, Product}
import given
import service/common_service
import model/common_model.{Id}
import service/dolibarr/product/warehouse_service
import gleam/javascript/promise
import model/dolibarr/product/warehouse_model.{type Warehouse, Warehouse}
import gleam/list
import model/dolibarr/import_model.{type ProductDTO, type BillOfMaterialsDTO}

pub fn store(token, products_n_boms: #(List(ProductDTO), List(BillOfMaterialsDTO)))
{
	let #(product_dtos, bom_dtos) = products_n_boms
	// foreach product
	use #(_, products) <- promise.try_await({
		use #(warehouses, products), product_dto: ProductDTO <-
			common_service.sequential_batch_fold(product_dtos, #([], []))
		// check if warehouse exists in existing_warehouse
		use warehouse <- promise.try_await({
			let found = warehouses |> list.find(fn(w: Warehouse) {
			w.ref == import_model.get_ref_warehouse(product_dto)
			})
			use _ <- given.error(found, fn(warehouse) {
				promise.resolve(Ok(warehouse))
			})
			let warehouse = product_dto
				|> import_model.compute_warehouse
			use id <- promise.try_await(token
				|> warehouse_service.create(warehouse))
			promise.resolve(Ok(Warehouse(..warehouse, id: Id(id))))
		})
		let warehouses = [warehouse, ..warehouses]
		// check if product exists in existing produts
		use product <- promise.try_await({
			let found = products |> list.find(fn(p: Product) {
			p.ref == import_model.get_ref(product_dto)
			})
			use _ <- given.error(found, fn(product) {
				promise.resolve(Ok(product))
			})
			let product = product_dto
				|> import_model.compute_product(warehouse.id)
			use id <- promise.try_await(token
				|> product_service.create(product))
			promise.resolve(Ok(Product(..product, id: Id(id))))
		})
		// insert product then push to existing products
		let products = [product, ..products]
		// insert stock
		let stock = product_dto |> import_model.compute_stock(product.id, warehouse.id)
		use _ <- promise.try_await(
			case stock.quantity
			{
				0. -> promise.resolve(Ok(0))
				_ -> token |> stock_service.create(stock)
			}
		)
		promise.resolve(Ok(#(warehouses, products)))
	})
	// foreach bom
		// insert bom and items
	let boms = list.map(bom_dtos, import_model.compute_bom(_, products))
	token |> bills_of_materials_service.import_(boms)
}
