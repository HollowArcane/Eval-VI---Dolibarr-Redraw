function BtnDelete(event)
{
    return tag('button',
        {
            'class': 'btn btn-secondary text-danger',
            'data-mdb-ripple-init': true,
            'onclick': event
        },
        [
            icon({}, ['fa', 'fa-trash'])
        ]
    );
}

function PaginationPage()
{
    return tag('li', {'class': 'page-item'}, [
        tag('a', {'href': '#', 'class': 'slot page-link'}, [])
    ])
}

function BtnUpdate(event)
{
    return tag('button',
        {
            'class': 'btn btn-secondary text-info',
            'data-mdb-ripple-init': true,
            'data-mdb-modal-init': true,
            'data-mdb-target': '#modal',
            'onclick': event
        },
        [
            icon({}, ['fa', 'fa-pencil'])
        ]
    );
}