import gleam/int

pub opaque type NonZero
{ NonZero(value: Int) }

pub const one = NonZero(1)

pub fn new(value: Int)
{
    case value
    {
        0 -> Error("Cannot accept 0 as NonZero")
        i -> Ok(NonZero(i))
    }
}

pub fn modulo(value: Int, base: NonZero)
{
    let assert Ok(value) = int.modulo(value, base.value)
    value
}