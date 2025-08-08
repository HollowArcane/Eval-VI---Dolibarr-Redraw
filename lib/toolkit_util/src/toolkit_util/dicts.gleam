import gleam/dict

pub fn sum(dict: dict.Dict(a, b), map: fn(a, b) -> Float) -> Float
{
    use acc, k, v <- dict.fold(dict, 0.)
    acc +. map(k, v)
}