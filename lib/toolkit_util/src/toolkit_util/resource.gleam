pub fn defer(value: a, call: fn() -> b)
{
    call()
    value
}

pub fn lazy_defer(then: fn(a) -> b, first call: fn() -> a)
{ call() |> then } 

pub fn defer_close(a, closer: fn(a) -> Nil, next: fn() -> e) -> e
{
    let result = next()
    closer(a)
    result
}

pub fn catch(result: Result(a, b), next: fn(a) -> b) -> b
{
    case result
    {
        Ok(something) -> next(something)
        Error(default) -> default
    }
}