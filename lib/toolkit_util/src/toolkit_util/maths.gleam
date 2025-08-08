import gleam/float
import gleam/int

pub fn lerp(v: Float, min: Float, max: Float) -> Float
{ v *. {min -. max} +. min }

pub fn map(v: Float, v_min: Float, v_max: Float, min: Float, max: Float) -> Float
{ lerp({v -. v_min} /. {v_max -. v_min}, min, max) }

pub fn int_lerp(v: Float, min: Int, max: Int) -> Int
{ lerp(v, min |> int.to_float, max |> int.to_float)
       |> float.truncate
}

pub fn int_map(v: Int, v_min: Int, v_max: Int, min: Int, max: Int) -> Int
{ map(v |> int.to_float, v_min |> int.to_float, v_max |> int.to_float, min |> int.to_float, max |> int.to_float)
       |> float.truncate
}