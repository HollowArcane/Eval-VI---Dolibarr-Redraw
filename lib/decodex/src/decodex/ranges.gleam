import gleam/int
import gleam/string
import gleam/dynamic/decode
import gleam/order.{type Order}

pub type Equal(a)
{ Equal(value: a, reference: a) }

pub type RangedSize(a)
{
    RangedSize(
        value: a,
        min: Bound(Int),
        max: Bound(Int)
    )
}

pub type Ranged(a)
{
    Ranged(
        value: a,
        min: Bound(a),
        max: Bound(a)
    )
}

pub type Bound(a)
{
    Inclusive(value: a)
    Exclusive(value: a)
    BoundLess
}

pub fn equal_decoder(reference: a) -> fn(a) -> decode.Decoder(Equal(a))
{
    fn(value) {
        case value == reference
        {
            True -> decode.success(Equal(value, reference))
            False -> decode.failure(Equal(value, value), "EqualTo:" <> string.inspect(reference))
        }
    }
}

pub fn size_decoder(min: Bound(Int), max: Bound(Int), sizer: fn(a) -> Int) -> fn(a) -> decode.Decoder(RangedSize(a))
{ fn(value) { range(sizer(value), min, max, int.compare) |> decode.map(fn(_) {RangedSize(value, min, max)}) } }

pub fn range_decoder(min: Bound(a), max: Bound(a), comparator: fn(a, a) -> Order) -> fn(a) -> decode.Decoder(Ranged(a))
{ fn(value) { range(value, min, max, comparator) |> decode.map(Ranged(_, min, max)) } }

fn range(value: a, min: Bound(a), max: Bound(a), comparator: fn(a, a) -> Order)
{
    case min
    {
        Exclusive(min_value) -> {
            case comparator(value, min_value)
            {
                order.Gt -> decode.success(value)
                _ -> decode.failure(value, "GreaterThan:" <> string.inspect(min_value))
            }
        }
        Inclusive(min_value) -> {
            case comparator(value, min_value)
            {
                order.Lt -> decode.failure(value, "GreaterOrEqualTo:" <> string.inspect(min_value))
                _ -> decode.success(value)
            }
        }
        BoundLess -> decode.success(value)
    } |> decode.then(fn(value) {
        case max
        {
            Exclusive(max_value) -> {
                case comparator(max_value, value)
                {
                    order.Gt -> decode.success(value)
                    _ -> decode.failure(value, "LessThan:" <> string.inspect(max_value))
                }
            }
            Inclusive(max_value) -> {
                case comparator(max_value, value)
                {
                    order.Lt -> decode.failure(value, "LessOrEqualTo:" <> string.inspect(max_value))
                    _ -> decode.success(value)
                }
            }
            BoundLess -> decode.success(value)
        }
    })
}