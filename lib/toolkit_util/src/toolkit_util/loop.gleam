import gleam/list

pub type LoopState(a)
{
    Continue(state: a)
    Break(state: a)
}

pub fn for(state: a, while check: fn(a) -> Bool, do loop_body: fn(a) -> LoopState(a)) -> a
{
    case check(state)
    {
        False -> state
        True -> case loop_body(state)
        {
            Continue(state) -> for(state, check, loop_body)
            Break(state) -> state
        }
    }
}

pub fn try_for(state: a, while check: fn(a) -> Bool, do loop_body: fn(a) -> LoopState(Result(a, b)))
{
    case check(state)
    {
        False -> Ok(state)
        True -> case loop_body(state)
        {
            Continue(Ok(state)) -> try_for(state, check, loop_body)
            Continue(Error(error)) -> Error(error)
            Break(state) -> state
        }
    }
}

pub fn forever(state: a, do loop_body: fn(a) -> LoopState(a)) -> a
{ for(state, fn(_) {True}, loop_body) }

pub fn try_forever(state: a, do loop_body: fn(a) -> LoopState(Result(a, b)))
{ try_for(state, fn(_) {True}, loop_body) }

pub fn map(list: List(a), map: fn(Int, a) -> b) -> List(b)
{
    let result = {
        use v, row <- list.fold(list, #(0, []))
        #(v.0 + 1, [map(v.0, row), ..v.1])
    }
    result.1 |> list.reverse
}