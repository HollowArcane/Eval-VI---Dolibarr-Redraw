import service/dolibarr/manufacture/manufacturing_order_service
import util/api_request.{ApiError}
import model/dolibarr/product/warehouse_model
import model/dolibarr/manufacture/bill_of_materials_model
import hooks/common_hooks
import service/dolibarr/product/warehouse_service
import service/dolibarr/manufacture/bills_of_materials_service
import service/dolibarr/product/product_service
import model/dolibarr/product/product_model
import util/swal
import gleam/javascript/promise
import service/csrf_token_service
import gleam/dynamic/decode
import view/components/stock_asap
import gleam/list
import model/dolibarr/manufacture/manufacturing_order_model
import view/components/common
import redraw/dom/attribute
import util/errors
import view/components/bs5
import view/page/page
import redraw/dom/html
import view/templates/template
import redraw


pub fn create_page()
{
	use <- redraw.component__("ManufacturingOrderMultiplePage")

	let #(submitting, set_submitting) = redraw.use_state(False)

	let #(verdict, set_verdict) = redraw.use_state([])
	let #(mos, set_mos) = redraw.use_state([])
	let #(boms, _) = common_hooks.use_fetched_state(
		bills_of_materials_service.fetch_all,
		"Erreur lors de la récupérations des fabrications"
	)
	let boms_dict = redraw.use_memo(fn() {bill_of_materials_model.options(boms)}, #(boms))

	let #(products, _) = common_hooks.use_fetched_state(
		product_service.fetch_all,
		"Erreur lors de la récupérations des produits"
	)
	let products_dict = redraw.use_memo(fn() {product_model.keyed(products)}, #(products))

	let #(warehouses, _) = common_hooks.use_fetched_state(
		warehouse_service.fetch_all,
		"Erreur lors de la récupérations des entrepôts"
	)
	let warehouses_dict = redraw.use_memo(fn() {warehouse_model.keyed(warehouses)}, #(warehouses))

	let service = redraw.use_callback(fn() {
		use token <- csrf_token_service.require
		set_submitting(True)

		use response <- promise.await(token |> manufacturing_order_service.manufacture_all(list.reverse(mos)))
		set_submitting(False)
		case response
		{
			Error(ApiError(message)) -> swal.error("Erreur", message)
			Error(e) -> {
				echo e
				swal.error("Erreur", "Une erreur est survenue. Veuillez réessayer ultérieurement.")
			}
			Ok(verdict) -> {
				// swal.success("", "Fabrications effectuées avec succès")
				set_verdict(verdict)
				set_mos([])
				set_submitting(False)
			}
		} |> promise.resolve
	}, #(mos))

	// button final submit -> batch create + update * 2 list
	template.home("/manufacturing-order/multiple", html.div([], [
		// button final submit
		common.title([
			stock_asap.btn_primary_cta("Fabriquer Tout", submitting, service),
			html.text("Fabrication Multiple"),
		]),
		html.section([], [
			bs5.card([], [{
				// form
				use errors <- page.create_form(
					reset: submitting,
					on_submit: decode.run(_, manufacturing_order_model.form_decoder(boms)),
					service: fn(_, mo) {
						// form submit -> push item to list
						set_mos([mo, ..mos])
						promise.resolve(Ok(Nil))
					},
					success_message: "",
					then: fn() { Nil }
				)
				[
//					bs5.text_input("Réference", errors |> errors.get("ref"), [attribute.name("ref")]),
//					bs5.text_input("Libellé", errors |> errors.get("label"), [attribute.name("label")]),
					bs5.select(boms_dict, "Fabrication", errors |> errors.get("id_bill_of_materials"), [attribute.name("id_bill_of_materials")]),
					bs5.number_input("Quantité", errors |> errors.get("quantity"), [attribute.name("quantity")]),
				]
			}])
		]),
		html.div([attribute.class("mt-3")], [
			// list of items
			case mos
			{
				[] -> redraw.fragment([])
				_ -> common.table(
					list.reverse(mos) |> list.map(manufacturing_order_model.format_card(_, products_dict, warehouses_dict)),
					loading: False,
					on_update: fn(_, _) {Nil},
					on_delete: fn(_) {Nil},
					on_export_pdf: fn(_) {Nil}
				)
			}
		]),
		html.div([attribute.class("mt-3")], [
			case verdict
			{
				[] -> redraw.fragment([])
				_ -> common.table(
					verdict |> list.map(manufacturing_order_model.format_verdict(_, products_dict, warehouses_dict)),
					loading: False,
					on_update: fn(_, _) {Nil},
					on_delete: fn(_) {Nil},
					on_export_pdf: fn(_) {Nil}
				)
			}
		])
	]))
}
