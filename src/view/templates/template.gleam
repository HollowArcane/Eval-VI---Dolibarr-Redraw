import view/components/fx
import redraw/dom/attribute
import redraw/dom/html
import view/components/bs5

pub fn home(active, content)
{
    html.div([attribute.id("container")], [
        html.aside([], [
            fx.sidenav(active, #("/product", "Stock Asap"), [
                #("Stock", [
                    #("/product", "Produits"),
                    #("/warehouse", "Entrepôts"),
                ]),
                #("Frabrication", [
                    #("#", "Ordre de Fabrication"),
                ]),
            ])
        ]),
        html.main([], [bs5.container([content])]),
    ])
}