import view/components/fx
import redraw/dom/attribute
import redraw/dom/html
import view/components/bs5

pub fn home(active, content)
{
    html.div([attribute.id("container")], [
        html.aside([], [
            fx.sidenav(active, #("/", "Stock Asap"), [
                #("", [
                    #("/", "Tableau de Bord"),
                    #("/import", "Import"),
                ]),
                #("Stock", [
                    #("/product", "Produits"),
                    #("/warehouse", "Entrepôts"),
                    #("/stock", "Stock"),
                ]),
                #("Frabrication", [
                    #("/bill-of-materials", "Fabrication"),
                    #("/manufacturing-order", "Ordre de Fabrication"),
                    #("/manufacturing-order/multiple", "Multiple Fabrication"),
                ]),
                #("", [
                    #("/logout", "Se Déconnecter"),
                ]),
            ])
        ]),
        html.main([], [bs5.container([content])]),
    ])
}
