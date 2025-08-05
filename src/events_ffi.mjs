export function getFormData(event)
{
    event.preventDefault();
    return new FormData(event.target);
}

export function getValue(event)
{ return event.target.value || ""; }