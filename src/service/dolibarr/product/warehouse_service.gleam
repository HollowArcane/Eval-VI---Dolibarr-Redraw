import model/dolibarr/product/warehouse_model
import service/dolibarr_service

pub fn list(token)
{ dolibarr_service.list(token, "llx_entrepot", warehouse_model.api_decoder()) }