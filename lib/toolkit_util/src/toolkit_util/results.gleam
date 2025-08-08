pub fn invert(a: Result(a, b)) -> Result(b, a)
{
    case a
    {
        Ok(v) -> Error(v)
        Error(v) -> Ok(v) 
    }
}

pub fn guard_ok(value: Result(a, b), return v: fn(a) -> c, or_else or_else: fn(b) -> c)
{
    case value
    {
        Ok(ok) -> v(ok)
        Error(error) -> or_else(error)
    }
}

pub fn guard_error(value: Result(a, b), return v: fn(b) -> c, then then: fn(a) -> c)
{
    case value
    {
        Ok(value) -> then(value)
        Error(e) -> v(e)
    }
}