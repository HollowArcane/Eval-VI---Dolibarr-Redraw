import gleam/int
import util/api_request
import gleam/result
import gleam/javascript/promise
import util/filter
import model/dolibarr/product/warehouse_filter
import service/common_service
import model/dolibarr/product/warehouse_model.{type Warehouse}
import service/dolibarr_service

pub fn import_(token, warehouses)
{ common_service.batch(warehouses, create(token, _)) }

pub fn fetch(token, at page, where filter)
{ dolibarr_service.list(token, ["warehouses"], warehouse_model.decoder(), page, filter |> warehouse_filter.format |> filter.to_filters)
    |> promise.map(result.map(_, api_request.get_response_body))}

pub fn create(token, warehouse)
{ dolibarr_service.create(token, ["warehouses"], warehouse_model.to_json(warehouse))
    |> promise.map(result.map(_, api_request.get_response_body)) }

pub fn delete(token, warehouse: Warehouse)
{ dolibarr_service.delete(token, ["warehouses", int.to_string(warehouse.id.value)])
    |> promise.map(result.map(_, api_request.get_response_body)) }
    
pub fn fetch_all(token)
{
    token |> dolibarr_service.fetch_all(
        at: ["warehouses"],
        expect: warehouse_model.decoder(), 
        page: 1,
        where: [],
        take: 1000
    ) |> promise.map(result.map(_, api_request.get_response_body)) 
}
