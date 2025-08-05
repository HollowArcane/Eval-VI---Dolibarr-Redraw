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
    let view_product_page = product.create_page()
    let view_warehouse_page = warehouse.create_page()

    use <- redraw.component__("Root")
    case route.get()
    {
        [] -> {
            route.go_to("/login")
            common.title([html.text("You are being redirected")])
        }

        ["login"] -> view_login_page()
        ["product"] -> view_product_page()
        ["warehouse"] -> view_warehouse_page()

        _ -> common.title([html.text("Not Found")])
    }
}