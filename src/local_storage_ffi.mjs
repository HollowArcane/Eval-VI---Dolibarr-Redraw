import * as $stdlib from "./gleam.mjs";

export function get(key)
{
    try
    {
        const item = localStorage.getItem(key);
        if(typeof item === 'undefined' || item === null)
        { return new $stdlib.Error(`${key} is not defined`); }
        return new $stdlib.Ok(item);
    }
    catch(e)
    { return new $stdlib.Error(e.message); }
}

export function set(key, value)
{
    try
    { return new $stdlib.Ok(localStorage.setItem(key, value)); }
    catch(e)
    { return new $stdlib.Error(e.message); }
}

export function remove(key)
{
    try
    { return new $stdlib.Ok(localStorage.removeItem(key)); }
    catch(e)
    { return new $stdlib.Error(e.message); }
}