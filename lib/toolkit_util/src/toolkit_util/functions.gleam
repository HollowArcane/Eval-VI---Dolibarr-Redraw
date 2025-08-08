pub fn then(first: fn(a) -> b, then: fn(b) -> c) -> fn(a) -> c
{ fn(x: a) -> c {first(x) |> then} }

pub fn lazy(value: a) -> fn() -> a
{ fn() {value} }

pub fn flip(function: fn(a, b) -> c) -> fn(b, a) -> c
{ fn(a, b) {function(b, a)} }