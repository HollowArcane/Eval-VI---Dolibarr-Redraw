import gleam/function
// import gleam/option.{Some}
import util/filter
import model/dolibarr/manufacture/bill_of_materials_filter.{type BillOfMaterialsFilter, }//BillOfMaterialsFilter}
import util/common_utils
import gleam/list
// import gleam/dynamic
import gleam/dynamic/decode
import gleam/int
import model/common_model.{type Id, Id}
import model/dolibarr/manufacture/bill_of_materials_model.{type BillOfMaterials, Enabled}
import gleam/javascript/promise
import util/api_request//.{ApiError}
import gleam/result
import service/common_service
import service/dolibarr_service

pub fn fetch(token, at page, where filter: BillOfMaterialsFilter)
{
    dolibarr_service.list(token, ["boms"], bill_of_materials_model.decoder(), page, filter |> bill_of_materials_filter.format |> filter.to_filters)  
        |> promise.map(result.map(_, api_request.get_response_body)) 
}

pub fn fetch_one(token, id: Id(BillOfMaterials))
{
    dolibarr_service.fetch_one(token,
        ["boms", int.to_string(id.value)],
        {
            use bom <- decode.then(bill_of_materials_model.decoder())
            decode.success(#(bom, bom.items))
        }
    ) |> promise.map(result.map(_, api_request.get_response_body)) 
}

pub fn fetch_all(token)
{
    token |> dolibarr_service.fetch_all(
        at: ["boms"],
        expect: bill_of_materials_model.decoder(), 
        page: 1,
        where: [],
        take: 1000
    ) |> promise.map(result.map(_, api_request.get_response_body)) 
}

pub fn import_(token, boms)
{ common_service.batch(boms, create(token, _)) }

fn create_line(token, id_parent: Id(BillOfMaterials), item: bill_of_materials_model.Item)
{ dolibarr_service.create(token, ["boms", int.to_string(id_parent.value), "lines"], bill_of_materials_model.item_to_json(item))
    |> promise.map(result.map(_, api_request.get_response_body)) }


pub fn create(token, bom: BillOfMaterials)
{
    use id <- promise.try_await(
        dolibarr_service.create(token, ["boms"], bill_of_materials_model.to_json(bom))
            |> promise.map(result.map(_, api_request.get_response_body))
    )
    let items = promise.await_list({
        use item <- list.map(bom.items)
        create_line(token, Id(id), item)
    })
    use items <- promise.await(items)
    use _ <- promise.try_await(
	common_utils.promise(fn() {list.try_map(items, function.identity)})
	)
	update(token, bill_of_materials_model.BillOfMaterials(..bom,
		id: Id(id),
		status: Enabled
	))
}

pub fn delete(token, bom: BillOfMaterials)
{ dolibarr_service.delete(token, ["boms", int.to_string(bom.id.value)])
    |> promise.map(result.map(_, api_request.get_response_body)) }

pub fn update(token, bom: BillOfMaterials)
{ dolibarr_service.update(token, ["boms", int.to_string(bom.id.value)], bom |> bill_of_materials_model.to_json, bill_of_materials_model.decoder())
    |> promise.map(result.map(_, api_request.get_response_body)) }
