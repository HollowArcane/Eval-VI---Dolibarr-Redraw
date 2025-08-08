pub type RecursionState(a, b)
{
    Continue(value: a)
    End(value: b)
}

pub fn start(value: a, function: fn(a) -> RecursionState(a, b)) -> b
{
    case function(value)
    {
        Continue(value) -> start(value, function)
        End(result) -> result
    }
}