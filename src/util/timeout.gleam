@external(javascript, "../timeout_ffi.mjs", "set_timeout")
pub fn set(then: fn() -> Nil, delay_millis: Int) -> Nil
