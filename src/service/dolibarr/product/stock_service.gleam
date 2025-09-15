import util/filter
import model/dolibarr/product/stock_filter.{type StockFilter}
import gleam/pair
import gleam/list
import model/dolibarr/product/stock_model.{type Stock}
import gleam/javascript/promise
import util/api_request
import gleam/result
import service/dolibarr_service


pub fn fetch_all(token)
{
    dolibarr_service.fetch_all(token, at: ["stockmovements"], expect: stock_model.decoder(), page: 1, take: 1000, where: [])  
        |> promise.map(result.map(_, api_request.get_response_body)) 
        |> promise.map(result.map(_, pair.first)) 
}

pub fn fetch(token, at page, where filter: StockFilter)
{
    token |> dolibarr_service.fetch_all(at: ["stockmovements"], expect: stock_model.decoder(), page:, take: 1000, where: filter |> stock_filter.format |> filter.to_filters)  
        |> promise.map(result.map(_, api_request.get_response_body)) 
}

pub fn import_(token, stocks)
{
	use promise, stock <- list.fold(stocks, promise.resolve(Ok(0)))
	use _ <- promise.try_await(promise)
	create(token, stock)
}

pub fn create(token, stock: Stock)
{ dolibarr_service.create(token, ["stockmovements"], stock_model.to_json(stock))
    |> promise.map(result.map(_, api_request.get_response_body)) }
