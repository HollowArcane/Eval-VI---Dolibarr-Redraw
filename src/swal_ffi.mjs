export function success(title, message)
{
    Swal.fire({
        text: message,
        title: title,
        icon: 'success'
    });
}
export function error(title, message)
{
    Swal.fire({
        text: message,
        title: title,
        icon: 'error'
    });
}
export function info(title, message)
{
    Swal.fire({
        text: message,
        title: title,
        icon: 'info'
    });
}