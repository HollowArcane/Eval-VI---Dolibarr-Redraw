import service/dolibarr/product/stock_service
import gleam/option.{Some}
import model/dolibarr/product/stock_filter.{StockFilter}
import model/common_model.{type Id}
import gleam/int
import gleam/javascript/promise
import util/api_request
import gleam/result
import util/filter
import model/dolibarr/product/product_filter.{type ProductFilter}
import service/common_service
import model/dolibarr/product/product_model.{type Product}
import service/dolibarr_service

pub fn fetch_one(token, id_product: Id(Product))
{
    use #(stocks, _) <- promise.try_await(stock_service.fetch(token, at: 1, where:  StockFilter(id_product: Some(id_product))))
    use product <- promise.try_await(
	dolibarr_service.fetch_one(token, ["products", int.to_string(id_product.value)], expect: product_model.decoder()) 
        |> promise.map(result.map(_, api_request.get_response_body)) 
	)
	promise.resolve(Ok(#(product,stocks)))
}

pub fn fetch(token, at page, where filter: ProductFilter)
{
    let filters = filter.to_filters(product_filter.format(filter))
    dolibarr_service.list(token, ["products"], product_model.decoder(), page, filters)  
        |> promise.map(result.map(_, api_request.get_response_body)) 
}

pub fn fetch_all(token)
{
    token |> dolibarr_service.fetch_all(
        at: ["products"],
        expect: product_model.decoder(), 
        page: 1,
        where: [],
        take: 1000
    ) |> promise.map(result.map(_, api_request.get_response_body)) 
}

pub fn import_(token, products)
{ common_service.batch(products, create(token, _)) }

pub fn create(token, product: Product)
{ dolibarr_service.create(token, ["products"], product_model.to_json(product))
    |> promise.map(result.map(_, api_request.get_response_body)) }

pub fn delete(token, product: Product)
{ dolibarr_service.delete(token, ["products", int.to_string(product.id.value)])
    |> promise.map(result.map(_, api_request.get_response_body)) }
