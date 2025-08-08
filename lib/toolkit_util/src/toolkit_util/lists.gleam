import toolkit_util/resource
import gleam/order
import gleam/dict
import gleam/list

pub fn sum(data: List(a), map: fn(a) -> Float)
{
    use sum, value <- list.fold(data, 0.)
    map(value) +. sum
}

pub fn ordered_values(map: dict.Dict(a, b), order: fn(a, a) -> order.Order)
{
    map |> dict.to_list
        |> list.sort(fn(v1, v2) {order(v1.0, v2.0)})
        |> list.map(fn(v) {v.1})
}

pub fn index(data: List(a)) -> dict.Dict(Int, a)
{
    list.range(0, list.length(data))
        |> list.zip(data)
        |> dict.from_list
}

pub fn map_index(data: List(a), mapper: fn(Int, a) -> a)
{
    {
        use #(data, index), value <- list.fold(data, #([], 0))
        #([mapper(index, value), ..data], index + 1)
    }.0
}

pub fn fold_index(data: List(a), initial_state: b, folder: fn(b, Int, a) -> b) -> b
{
    use <- resource.lazy_defer(fn(res: #(Int, b)) {res.1})
    use #(index, state), value <- list.fold(data, #(0, initial_state))
    #(index + 1, folder(state, index, value))
}

pub fn split2(data: List(a)) -> #(List(a), List(a))
{
    let result = {
        use #(acc, i), value <- list.fold(data, #(#([], []), 0))
        #(case i % 2
        {
            0 -> #([value, ..acc.0], acc.1)
            _ -> #(acc.0, [value, ..acc.1])
        }
        , i+1)
    }.0
    #(result.0 |> list.reverse, result.1 |> list.reverse)
}

pub fn filter_ok(list: List(Result(a, b))) -> List(a)
{
    use <- resource.lazy_defer(list.reverse)
    use acc, value <- list.fold(list, [])
    case value
    {
        Ok(v) -> [v, ..acc]
        Error(_) -> acc
    }
}

pub fn filter_error(list: List(Result(a, b))) -> List(b)
{
    use <- resource.lazy_defer(list.reverse)
    use acc, value <- list.fold(list, [])
    case value
    {
        Ok(_) -> acc
        Error(e) -> [e, ..acc]
    }
}

pub fn split_ok_error(list: List(Result(a, b)))
{
    use <- resource.lazy_defer(fn(result: #(List(a), List(b))) {
        #(result.0 |> list.reverse, result.1 |> list.reverse)
    })
    use #(oks, errors), value <- list.fold(list, #([], []))
    case value
    {
        Ok(v) -> #([v, ..oks], errors)
        Error(e) -> #(oks, [e, ..errors])
    }
}

pub fn guard_all_ok(list: List(Result(a, b)), then: fn(List(a)) -> c, or_else: fn(List(b)) -> c)
{
    let #(oks, errors) = split_ok_error(list)
    case errors
    {
        [] -> then(oks)
        errors -> or_else(errors)
    }
}

pub fn guard_some_error(list: List(Result(a, b)), then: fn(List(b)) -> c, or_else: fn(List(a)) -> c)
{
    let #(oks, errors) = split_ok_error(list)
    case errors
    {
        [] -> or_else(oks)
        errors -> then(errors)
    }
}

pub fn guard_all_error(list: List(Result(a, b)), then: fn(List(b)) -> c, or_else: fn(List(a)) -> c)
{
    let #(oks, errors) = split_ok_error(list)
    case oks
    {
        [] -> then(errors)
        oks -> or_else(oks)
    }
}

pub fn guard_some_ok(list: List(Result(a, b)), then: fn(List(a)) -> c, or_else: fn(List(b)) -> c)
{
    let #(oks, errors) = split_ok_error(list)
    case oks
    {
        [] -> or_else(errors)
        oks -> then(oks)
    }
}

pub fn guard_empty(list: List(a), then: fn() -> b, or_else: fn(#(a, List(a))) -> b)
{
    case list
    {
        [] -> then()
        [head, ..tail] -> or_else(#(head, tail))
    }
}