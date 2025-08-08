import gleam/option.{type Option, Some, None}

pub fn guard_none(value: Option(a), return v: fn() -> b, or_else or_else: fn(a) -> b)
{
    case value
    {
        Some(value) -> or_else(value)
        None -> v()
    }
}

pub fn guard_some(value: Option(a), return v: fn() -> b, or_else or_else: fn() -> b)
{
    case value
    {
        None -> or_else()
        Some(_) -> v()
    }
}