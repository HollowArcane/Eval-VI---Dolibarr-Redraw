import gleam/float
import gleam/int
import gleam/dynamic/decode

pub fn int_decoder()
{
    decode.one_of(
        decode.int, [
        decode.string
            |> decode.then(fn(str) {
                case int.parse(str)
                {
                    Ok(i) -> decode.success(i)
                    Error(_) -> decode.failure(0, "Int") 
                    
                }
            })
    ])
}

pub fn decoder()
{
    decode.one_of(
        decode.float, [
        decode.int
            |> decode.map(int.to_float),
        decode.string
            |> decode.then(fn(str) {
                case float.parse(str), int.parse(str)
                {
                    Ok(f), _ -> decode.success(f)
                    _, Ok(i) -> decode.success(int.to_float(i))
                    Error(_), Error(_) -> decode.failure(0., "Float") 
                    
                }
            })
    ])
}
