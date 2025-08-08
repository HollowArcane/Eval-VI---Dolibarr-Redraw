
pub fn equals(e1: a, e2: a)
{ e1 == e2 }

pub fn not_equals(e1: a, e2: a)
{ e1 != e2 }

pub fn check(guard: Bool, then v1: a, or_else v2: a)
{
    case guard
    {
        True -> v1
        False -> v2
    }
}