import given
import gleam/int
import gleam/list

pub fn spread(active: Int, page_max: Int, side: Int, middle: Int)
{
    let side = int.max(side, 1)
    let middle = int.max(middle, 0)
    let page_max = int.max(page_max, 1)
    
    let active = int.clamp(active, min: 1, max: page_max)
    let left_start = 1
    let left_end = int.min(side, page_max)

    let middle_start = int.max(active - middle, 1 + side)
    let middle_end = int.min(active + middle, page_max - side)

    let right_start = int.max(page_max - side, 1)
    let right_end = page_max

    // left side (reversed because no loop) 
    let pages = list.range(left_end, left_start)
        |> list.map(int.to_string)

    // transition
    let pages = case middle_start == side + 1
    {
        True -> pages
        False -> ["", ..pages]
    }

    use <- given.that(middle_start > middle_end, fn() {list.reverse(pages)})
    // middle
    let pages = {
        list.fold(
            list.range(middle_start, middle_end)
                |> list.map(int.to_string),
            pages, list.prepend
        )
    }

    // transition
    let pages = case middle_end == page_max - side
    {
        True -> pages
        False -> ["", ..pages]
    }

    use <- given.that(middle_start > middle_end, fn() {list.reverse(pages)})
    // right side
    {
        list.fold(
            list.range(right_start, right_end)
                |> list.map(int.to_string),
            pages, list.prepend
        )
    }
}