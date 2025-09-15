import view/components/stock_asap
import gleam/http/response.{Response}
import util/swal
import service/dolibarr_service
import gleam/javascript/promise
import service/csrf_token_service
import view/components/chartjs/doughnut
import view/components/chartjs/line
import util/chart.{ Data, Dataset}
import view/components/fx
import redraw/dom/attribute
import redraw/dom/html
import view/components/common
import view/components/bs5
import view/templates/template
import redraw

pub fn create_page()
{
    let view_line = line.create_element()
    let view_doughnut = doughnut.create_element()

    use <- redraw.component__("DashboardPage")

	let reset_callback = redraw.use_callback(fn() {
		use token <- csrf_token_service.require()
		use response <- promise.await(dolibarr_service.reset(token))
		case response
		{
		  	Error(e) -> {
				echo e
				swal.error("Une erreur est survenue, veuillez réessayer ultérieurement", "")
			}
			Ok(Response(body:, ..)) -> swal.success(body, "")
		} |> promise.resolve
	}, #())

    template.home("/", html.div([], [
        common.title([
		stock_asap.btn_reset(reset_callback),
		html.text("Tableau de Bord")
	]),
        
        html.section([attribute.class("row")], [
            html.div([attribute.class("col-md-6 col-lg-4")], [
                bs5.card([attribute.class("p-4")], [
                    html.h2([attribute.class("fw-bold")], [html.text("Ventes")]),
                    html.p([], [html.text("2 353 315.01")])
                ]),
                html.br([]),
                bs5.card([attribute.class("p-4")], [
                    html.h2([attribute.class("fw-bold")], [html.text("Ventes")]),
                    html.p([], [html.text("2 353 315.01")])
                ]),
            ]),
            html.div([attribute.class("col-md-6 col-lg-8")], [
                fx.table(["Column 1", "Column 2", "Column 3", "Column 4"], html.tbody([], [
                    html.tr([], [
                        html.td([], [html.text("Value 1")]),
                        html.td([], [html.text("Value 2")]),
                        html.td([], [html.text("Value 3")]),
                        html.td([], [html.text("Value 4")]),
                    ]),
                    html.tr([], [
                        html.td([], [html.text("Value 1")]),
                        html.td([], [html.text("Value 2")]),
                        html.td([], [html.text("Value 3")]),
                        html.td([], [html.text("Value 4")]),
                    ]),
                    html.tr([], [
                        html.td([], [html.text("Value 1")]),
                        html.td([], [html.text("Value 2")]),
                        html.td([], [html.text("Value 3")]),
                        html.td([], [html.text("Value 4")]),
                    ]),
                    html.tr([], [
                        html.td([], [html.text("Value 1")]),
                        html.td([], [html.text("Value 2")]),
                        html.td([], [html.text("Value 3")]),
                        html.td([], [html.text("Value 4")]),
                    ]),
                ]))
            ])
        ]),
        html.section([attribute.class("row")], [
            html.div([attribute.class("col-md-6 col-lg-8")], [{
                let #(data, options) = chart.setup(Data(
                    labels: ["Field 1", "Field 2", "Field 3", "Field 4"],
                    datasets: [
                        Dataset("Dataset 1", [10., 20., 30., 40.]),
                        Dataset("Dataset 2", [40., 20., 30., 15.]),
                        Dataset("Dataset 3", [51., 27., 53. ,11.]),
                    ]
                ))
                view_line(line.Props(options:, data:), [])
            }]),
            html.div([attribute.class("col-md-6 col-lg-4")], [{
                let #(data, options) = chart.setup(Data(
                    ["Field 1", "Field 2", "Field 3", "Field 4"],
                    [Dataset("Dataset", [10., 20., 30., 40.]),]
                ))
                view_doughnut(doughnut.Props(options:, data:), [])
            }])
        ]),
    ]))

}
