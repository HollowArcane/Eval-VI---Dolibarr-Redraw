export function get()
{ return window.location.pathname; }

export function query()
{ return window.location.search; }

export function goTo(path)
{ window.location.href = path; }

export function encode(uri)
{ return encodeURIComponent(uri); }