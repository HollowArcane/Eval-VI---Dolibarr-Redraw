@external(javascript, "../swal_ffi.mjs", "success")
pub fn success(title: String, message: String) -> Nil

@external(javascript, "../swal_ffi.mjs", "error")
pub fn error(title: String, message: String) -> Nil

@external(javascript, "../swal_ffi.mjs", "info")
pub fn info(title: String, message: String) -> Nil

@external(javascript, "../swal_ffi.mjs", "confirm")
pub fn confirm(title: String, message: String, then: fn(Bool) -> a) -> Nil