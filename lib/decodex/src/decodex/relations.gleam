import gleam/string
import gleam/dynamic/decode
import gleam/list


pub type Existing(a)
{ Existing(value: a, items: List(a)) }

pub fn exists(rows: List(a))
{ fn(value) {
    case rows |> list.contains(value)
    {
        True -> decode.success(Existing(value, rows))
        False -> decode.failure(Existing(value, rows), "ExistIn:" <> string.inspect(rows))
    }
}}


pub type Unique(a)
{ Unique(value: a, among: List(a)) }

pub fn unique(rows: List(a))
{ fn(value) {
    case rows |> list.contains(value)
    {
        False -> decode.success(Unique(value, rows))
        True -> decode.failure(Unique(value, rows), "ExistIn:" <> string.inspect(rows))
    }
}}