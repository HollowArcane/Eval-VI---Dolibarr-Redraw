import gleam/javascript/promise.{type Promise}

pub fn promise(body: fn() -> a)
{
    use trigger <- promise.new
    trigger(body())
}

pub fn async(body: fn() -> a, then: fn(a) -> Promise(b))
{ promise.await(promise(body), then) }