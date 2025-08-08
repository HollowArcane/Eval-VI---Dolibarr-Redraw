import gleam/string
import gleam/dynamic/decode
import gleam/list

pub type Containing(a)
{ Containing(value: List(a), children: #(a, List(a))) }

pub type AllContained(a)
{ AllContained(value: List(a), container: List(a)) }

pub type Contained(a)
{ Contained(value: a, container: List(a)) }

pub fn contains_decoder(first: a, rest: List(a))
{
    fn(list: List(a)) {
        let not_contained = rest |> list.filter(fn(value) {!{list |> list.contains(value)}})
        case list |> list.contains(first), not_contained
        {
            True, [] -> decode.success(Containing(list, #(first, rest)))
            _, _ -> decode.failure(Containing(list, #(first, [])), "ShouldContainEach:" <> string.inspect([first, ..rest]))
        }
    }
}

pub fn contained_decoder(container: List(a))
{
    fn(value: a) {
        case container |> list.contains(value)
        {
            True -> decode.success(Contained(value:, container:))
            False -> decode.failure(Contained(value, []), "ShouldContainedIn:" <> string.inspect(container))
        }
    }
}

pub fn all_contained_decoder(container: List(a))
{
    fn(values: List(a)) {
        let not_contained = values |> list.filter(fn(value) {!{container |> list.contains(value)}})
        case not_contained
        {
            [] -> decode.success(AllContained(value: values, container:))
            _ -> decode.failure(AllContained(value: values, container: []), "AllShouldContainedIn:" <> string.inspect(container))
        }
    }
}

// regex match
// fix size check
// unique
// exists
// not