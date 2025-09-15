import util/csv
import hooks/common_hooks
import model/dolibarr/constant/country_model
import redraw/dom/attribute
import util/errors
import view/components/bs5
import model/dolibarr/product/warehouse_filter
import service/dolibarr/product/warehouse_service
import model/dolibarr/product/warehouse_model.{type Warehouse}
import view/page/page
import util/swal
import toolkit_util/resource
import service/csrf_token_service
import service/dolibarr/constant/country_service
import gleam/javascript/promise
import redraw

pub fn fetch_countries(set_countries)
{
    use <- resource.defer(Nil)
    use token <- csrf_token_service.require
    use response <- promise.await(country_service.fetch_all(token))
    case response
    {
        Ok(countries) -> set_countries(countries.body.0)
        Error(e) -> {
            echo e
            swal.error("Erreur", "Erreur lors de la récupération des Pays")
        }
    } |> promise.resolve
}

pub fn create_page()
{
    use <- redraw.component__("WarehousePage")

    let #(countries, set_countries) = redraw.use_state([])
    common_hooks.use_init(fn() {fetch_countries(set_countries)}, #())

    page.create_crud_plus(
        id: "warehouse",
        title: "Entrepôt",
        get_ref: fn(warehouse: Warehouse) {warehouse.ref},
        create_service: warehouse_service.create,
        read_service: warehouse_service.fetch,
        update_service: fn(_, _, _) { promise.resolve(Ok(Nil)) },
        delete_service: warehouse_service.delete,
        import_service: warehouse_service.import_,
        default_filter: warehouse_filter.new(),
        form_decoder: fn() {warehouse_model.form_decoder(countries)},
        csv_handler: csv.decode_file(_, warehouse_model.csv_decoder(countries)),
        filter_decoder: warehouse_filter.decoder,
        view_format: warehouse_model.format_view,
        pdf_list_format: warehouse_model.format_view,
        pdf_card_format: warehouse_model.format_view,
        csv_format: warehouse_model.format_csv,
        json_format: warehouse_model.to_json,
        render_create: render_create_form(countries, _),
        render_search: render_search_form(countries, _)
    )
}


fn render_create_form(countries, errors)
{[
    bs5.text_input("Réference", errors |> errors.get("ref"), [
        attribute.name("ref")
    ]),
    bs5.text_input("Description", errors |> errors.get("description"), [
        attribute.name("description")
    ]),
    bs5.text_input("Lieu", errors |> errors.get("location"), [
        attribute.name("location")
    ]),
    bs5.select(country_model.options(countries), "Pays", errors |> errors.get("id_country"), [
        attribute.name("id_country")
    ]),
]}
fn render_search_form(countries, errors)
{[
    bs5.text_input("Réference", errors |> errors.get("ref"), [
        attribute.name("ref")
    ]),
    bs5.text_input("Description", errors |> errors.get("description"), [
        attribute.name("description")
    ]),
    bs5.text_input("Lieu", errors |> errors.get("location"), [
        attribute.name("location")
    ]),
    bs5.select([
        #("", "Tous"),
        ..country_model.options(countries)
    ], "Pays", errors |> errors.get("id_country"), [
        attribute.name("id_country")
    ]),
]}
