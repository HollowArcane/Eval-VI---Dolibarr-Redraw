import gleam/javascript/promise.{type Promise}

pub fn async(body: fn() -> a, then: fn(a) -> Promise(b))
{
    promise.await({
        use trigger <- promise.new
        trigger(body())
    }, then)
}