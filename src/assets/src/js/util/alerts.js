const alerts = {
    error: function(message, title)
    {
        Swal.fire({
            icon: 'error',
            title: title || 'Error',
            text: message,
            showConfirmButton: true
        });
    },
    success: function(message, title)
    {
        Swal.fire({
            icon: 'success',
            title: title || 'Success',
            text: message,
            timer: 2000,
            showConfirmButton: false
        });
    },
    confirm: function(title)
    {
        return Swal.fire({
            title: title,
            showDenyButton: true,
            confirmButtonText: 'Yes',
            denyButtonText: 'No',
            customClass: {
                actions: 'my-actions',
                confirmButton: 'order-1',
                denyButton: 'order-2',
            },
        })
    }
};