import web/hooks
import model/dolibarr/product/warehouse_model
import service/dolibarr/product/warehouse_service
import service/csrf_token_service
import gleam/javascript/promise
import view/components/generic
import view/templates/template
import redraw/dom/html
import view/components/common
import redraw

pub fn create_page()
{
    use <- redraw.component__("WarehousePage")

    let #(warehouses, set_warehouses) = redraw.use_state([])
    
    hooks.use_init_effect(fn() {
        use token <- csrf_token_service.require
        
        use warehouses <- promise.await(warehouse_service.list(token))
        case warehouses 
        {
            Error(e) -> { echo e Nil }
            Ok(warehouses) -> set_warehouses(warehouses.body)
        } |> promise.resolve
    }, #())

    template.home("/warehouse", html.div([], [
        common.title([html.text("Liste des Entrepôts")]),
        case generic.render_table(warehouses, warehouse_model.format_view)
        {
            Ok(table) -> table
            Error(_) -> common.center_p("Aucune donnée trouvée")
        }
    ]))
}