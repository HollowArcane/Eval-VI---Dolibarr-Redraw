import gleam/order
import toolkit_util/calendar/date
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  1
  |> should.equal(1)
}

pub fn month_add_and_day_set_test()
{
    assert date.new(2025, 12, 15)
        |> date.add_month(1)
        |> date.set_day(0)
        |> Ok
        == date.strict_new(2025, 12, 31)
}

pub fn date_compare_test()
{
    // let assert Ok(d1) = date.strict_new(2026, 4, 1)
    // let assert Ok(d2) = date.strict_new(2026, 3, 1)
    let assert Ok(d1) = date.strict_new(2025, 5, 1)
    let assert Ok(d2) = date.strict_new(2025, 3, 30)
    assert d1 |> date.compare(d2) == order.Gt
}