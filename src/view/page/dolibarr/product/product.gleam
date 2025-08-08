import gleam/list
import util/html2pdf
import web/hooks
import redraw/dom/attribute
import view/components/bs5
import view/components/stock_asap
import view/components/common
import model/dolibarr/product/product_model
import service/dolibarr/product/product_service
import view/templates/template
import redraw/dom/html
import redraw

pub fn create_page()
{
    use <- redraw.component__("ProductPage")

    let #(page, set_page) = redraw.use_state(1)
    let #(table, data, load_data) = common.table(
        product_model.format_view,
        product_service.list
    )
    let data = list.map(data, product_model.format_view)

    let #(form, set_open) = {
        use get_error <- common.modal_form(
            title: "Insertion Produit",
            decoder: product_model.form_decoder(),
            service: product_service.create,
            then: fn() {load_data(page) "Produit inséré avec succès"})
        [
            bs5.text_input("Réference", get_error("ref"), [attribute.name("ref")]),
            bs5.text_input("Libellé", get_error("label"), [attribute.name("label")]),
            bs5.textarea("Description", get_error("description"), [attribute.name("description")]),
            bs5.number_input("Prix", get_error("price"), [attribute.name("price")]),
        ]
    }    

    hooks.use_init_effect(fn() {load_data(page)}, #(page))

    template.home("/product", html.div([], [
        form,
        common.title([
            stock_asap.btn_add(fn() {set_open(True)}),
            stock_asap.btn_export_pdf(fn() {
                html2pdf.generate_table("Liste des Produits", data)
            }),
            html.text("Liste des Produits"),
            common.pagination(page, set_page)
        ]),
        table
    ]))
}