import gleam/javascript/promise
import util/csv
import util/errors
import redraw/dom/attribute
import view/components/bs5
import model/dolibarr/product/product_filter
import service/dolibarr/product/product_service
import view/page/page
import model/dolibarr/product/product_model.{type Product}
import redraw

pub fn create_page() {
    use <- redraw.component__("ProductPage")

    page.create_crud_plus(
        id: "product",
        title: "Produit",
        get_ref: fn(product: Product) {product.ref},
        create_service: product_service.create,
        read_service: product_service.fetch,
        update_service: fn(_, _, _) { promise.resolve(Ok(Nil)) },
        delete_service: product_service.delete,
        import_service: product_service.import_,
        default_filter: product_filter.new(),
        form_decoder: product_model.form_decoder,
        csv_handler: csv.decode_file(_, product_model.csv_decoder()),
        filter_decoder: product_filter.decoder,
        view_format: product_model.format_view,
        pdf_list_format: product_model.format_view,
        pdf_card_format: product_model.format_view,
        csv_format: product_model.format_csv,
        json_format: product_model.to_json,
        render_create:,
        render_search:,
    )
}

pub fn render_create(errors)
{
    [
        bs5.text_input("Réference", errors |> errors.get("ref"), [
            attribute.name("ref"),
        ]),
        bs5.text_input("Libellé", errors |> errors.get("label"), [
            attribute.name("label"),
        ]),
        bs5.textarea("Description", errors |> errors.get("description"), [
            attribute.name("description"),
        ]),
        bs5.number_input("Prix", errors |> errors.get("price"), [
            attribute.name("price"),
        ]),
        bs5.checkbox("True", "Disponible à l'Achat", errors |> errors.get("status_buy"), [
            attribute.name("status_buy")
        ]),
        bs5.checkbox("True", "Disponible en Vente", errors |> errors.get("status"), [
            attribute.name("status")
        ]),
        bs5.checkbox("True", "Manufacturé", errors |> errors.get("finished"), [
            attribute.name("finished")
        ]),
    ]
}

fn render_search(errors)
{
    [
        bs5.text_input("Réference", errors |> errors.get("ref"), [
            attribute.name("ref")
        ]),
        bs5.text_input("Libellé", errors |> errors.get("label"), [
            attribute.name("label")
        ]),
        bs5.textarea("Description", errors |> errors.get("description"), [
            attribute.name("description")
        ]),
        bs5.number_input("Prix Min", errors |> errors.get("price_min"), [
            attribute.name("price_min")
        ]),
        bs5.number_input("Prix Max", errors |> errors.get("price_max"), [
            attribute.name("price_max")
        ]),
    ]
}
