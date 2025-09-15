import Swal from 'sweetalert2'

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
export function confirm(title, message, then)
{
    Swal.fire({
        title: title,
        message: message,
        showDenyButton: true,
        confirmButtonText: "Confirmer",
        denyButtonText: `Annuler`
    }).then((result) => then(result.isConfirmed));
}