@external(javascript, "../local_storage_ffi.mjs", "set")
pub fn set(key: String, value: String) -> Result(Nil, Nil)

@external(javascript, "../local_storage_ffi.mjs", "get")
pub fn get(key: String) -> Result(String, Nil)

@external(javascript, "../local_storage_ffi.mjs", "remove")
pub fn remove(key: String) -> Result(Nil, Nil)