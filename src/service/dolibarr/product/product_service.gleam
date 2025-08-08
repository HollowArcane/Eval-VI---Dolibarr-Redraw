import model/dolibarr/product/product_model.{type Product}
import service/dolibarr_service

pub fn list(token, page)
{ dolibarr_service.list(token, "products", product_model.decoder(), page) }

pub fn create(token, product: Product)
{ dolibarr_service.create(token, "products", product_model.to_json(product)) }