import view/templates/template
import gleam/list
import redraw/dom/html
import util/errors
import service/dolibarr/import_service
import model/dolibarr/import_model
import redraw/dom/attribute
import view/components/bs5
import view/page/page
import redraw

pub fn create_page()
{
	use <- redraw.component__("ImportPage")
	template.home("/import",
		bs5.card([], [
			html.h1([], [html.text("Import")]),
			page.create_form(
				reset: False,
				on_submit: import_model.decode_form,
				service: import_service.store,
				success_message: "Données importées avec succès",
				then: fn() {Nil},
				render:,
			)
		])
	)
}

fn render(errors)
{[
	case errors |> errors.all
	{
		[] -> redraw.fragment([])
		errors -> bs5.alert(bs5.danger, [], [
			html.ul([], {
				use error <- list.map(errors)
				html.li([], [html.text(error)])
			}),
		])
	},

	bs5.file_input("Fichier 1 - BOM", "", [attribute.name("file1")]),
	bs5.file_input("Fichier 2 - Produits", "", [attribute.name("file2")]),
]}
