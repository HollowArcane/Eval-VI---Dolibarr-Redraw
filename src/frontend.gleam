import view/page/dolibarr/manufacture/manufacturing_order_multiple
import view/page/dolibarr/product/product/card as product_card
import view/page/dolibarr/import_
import view/page/dolibarr/manufacture/manufacturing_order/card as mo_card
import view/page/dolibarr/manufacture/bill_of_materials/card as bom_card
import view/page/dolibarr/manufacture/manufacturing_order
import view/page/dolibarr/manufacture/bill_of_materials
import view/page/dolibarr/product/stock
import view/page/dolibarr/dashboard
import service/csrf_token_service
import view/page/dolibarr/product/warehouse
import view/components/common
import view/page/dolibarr/product/product
import util/route
import view/page/authentication/login
import redraw/dom/client
import redraw
import redraw/dom/html

pub fn main()
{
    let view_root = create_root()
    let assert Ok(root) = client.create_root("root")
    client.render(root, redraw.strict_mode([view_root()]))
}

fn create_root()
{
    let view_login_page = login.create_page()
    
    
    let view_dashboard = dashboard.create_page()
	let view_import = import_.create_page()
    
    let view_product_page = product.create_page()
    let view_product_card_page = product_card.create_page()
    let view_warehouse_page = warehouse.create_page()
    let view_stock_page = stock.create_page()
    
    let view_bill_of_materials_page = bill_of_materials.create_page()
    let view_bill_of_materials_card_page = bom_card.create_page()
    let view_manufacturing_order_page = manufacturing_order.create_page()
    let view_manufacturing_order_card_page = mo_card.create_page()
	let view_manufacturing_order_multiple_page = manufacturing_order_multiple.create_page()

    use <- redraw.component__("Root")
    case csrf_token_service.restore(), route.get()
    {
        Error(_), [] -> {
            route.go_to("/login")
            common.title([html.text("You are being redirected")])
        }

        _, ["login"] -> view_login_page()


        _, [] -> view_dashboard()
	_, ["import"] -> view_import()

        _, ["product"] -> view_product_page()
        _, ["product", id] -> view_product_card_page(product_card.Props(id))
        _, ["warehouse"] -> view_warehouse_page()
        _, ["stock"] -> view_stock_page()

        _, ["bill-of-materials"] -> view_bill_of_materials_page()
        _, ["bill-of-materials", id] -> view_bill_of_materials_card_page(bom_card.Props(id))
        _, ["manufacturing-order"] -> view_manufacturing_order_page()
        _, ["manufacturing-order", "multiple"] -> view_manufacturing_order_multiple_page()
        _, ["manufacturing-order", id] -> view_manufacturing_order_card_page(mo_card.Props(id))


        _, ["logout"] -> {
            let assert Ok(_) = csrf_token_service.remove()
            route.go_to("/login")
            redraw.fragment([])
        }

        _, _ -> common.not_found()
    }
}
