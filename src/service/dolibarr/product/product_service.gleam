import gleam/float
import model/dolibarr/product/product_model.{type Product}
import service/dolibarr_service

const llx_product = "llx_product"

pub fn list(token)
{ dolibarr_service.list(token, llx_product, product_model.decoder()) }

pub fn create(token, product: Product)
{
    let product_model.Product(ref:, label:, description:, price:, ..) = product
    dolibarr_service.create(token, llx_product, [
        #("ref", ref),
        #("label", label),
        #("description", description),
        #("price", float.to_string(price)),
    ])
}