import gleam/int
import gleam/list

pub type Pagination(a)
{ Pagination(items: List(a), active_page: Int, total_pages: Int, items_per_page: Int) }

pub fn get(data: List(b), no_page no: Int, items_per_page count: Int) -> Pagination(b)
{
    let total = data |> list.length
    let total_pages = {total - 1} / 10 + 1

    let no = int.clamp(no, 1, total_pages)

    Pagination(
        items: list.drop(data, count * {no - 1})
            |> list.take(count),
        active_page: no,
        total_pages:,
        items_per_page: count
    )
}