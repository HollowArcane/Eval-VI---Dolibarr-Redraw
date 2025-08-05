const BADGE_TYPE = {
    'Confirmed': 'success',
    'Cancelled': 'danger',
    'Archived': 'secondary',
    'Draft': 'info',
};

class Page extends BasePage
{
    constructor(table, form, spinner, text)
    {
        super(form, spinner, text);

        this.table = table;
        this.form = new FormHandler(form);

        this.init();
    }

    init()
    {
        this.token = this.requireToken();
        
        this.form.onsubmit(() => {
            this.startSubmit();
            this.read(this.form.formData());
        });

        this.read(this.form.formData());
    }

    read(formdata, page = 1)
    {
        request(`/api/expense?page=${page}&date_min=${formdata.get('date-min')}&date_max=${formdata.get('date-max')}`)
            .authorize(this.token).get()
                .then(this.render.bind(this))
                .catch(this.error.bind(this));
    }

    formatDate(isoDate)
    {
        return new Date(isoDate).toLocaleDateString("en-US", {
            year: "numeric",
            month: "long",
            day: "numeric"
        });
    }

    renderStatus(status)
    {
        return tag('p', {}, [
            tag('span', {'class': `badge badge-${BADGE_TYPE[status]}`}, [
                text(status)
            ])
        ]);
    }

    renderAmount(amount)
    {
        return tag('input', {
            'class': 'form-control',
            'value': amount,
            'type': 'number'
        }, []);
    }

    
    update(row)
    {
        request(`/api/expense`).authorize(this.token).json(row).put()
        .then(json => {
            alerts.success('', json.data.message);
            this.read(this.form.formData());
        })
        .catch(this.error.bind(this));
    }

    delete(row)
    {
        alerts.confirm('Are you sure you want to delete this element?')
        .then(response => {
            if(response.isConfirmed)
            {
                request(`/api/expense/${row.id}`).authorize(this.token).delete()
                    .then(json => {
                        alerts.success('', json.data.message);
                        this.read(this.form.formData());
                    })
                    .catch(this.error.bind(this));
            }
        });
    }

    render(data)
    {
        this.table.replaceChildren(...data.data.items.map(row => {
            const input = this.renderAmount(row.amount);
            return tag('tr', {'class': 'table-row', 'style': 'opacity: 0'}, [
                tag('td', {}, [tag('div', {'class': 'd-flex gap-1 align-items-center'}, [
                    BtnDelete(e => {
                        this.delete(row);
                    }),
                    BtnUpdate(e => {
                        row.amount = parseFloat(input.value);
                        row.status = parseInt(row.status); 
                        this.update(row);
                    })
                ])]),
                tag('td', {}, [text(row.number)]),
                tag('td', {}, [text(row.title)]),
                tag('td', {}, [text(row.description)]),
                tag('td', {}, [text(this.formatDate(row.expenseDate))]),
                tag('td', {}, [this.renderStatus(row.statusName)]),
                tag('td', {}, [input]),
                tag('td', {}, [text(row.campaignName)]),
            ]
        )}));

        gsap.to(".table-row", {
            duration: .1,
            opacity: 1, 
            stagger: 0.05,
            ease: "sine.out"
        });

        new Pagination(
            document.getElementById('pagination'),
            tag('li', {'class': 'page-item'}, [
                tag('a', {'class': 'page-link slot', 'href': '#'}, [text('1')])
            ]),
            data.data.total_pages,
            page => this.read(this.form.formData(), page)
        )
        .setPrevious(icon({}, ['fa', 'fa-chevron-left']))
        .setNext(icon({}, ['fa', 'fa-chevron-right']))
        .setActive(data.data.active_page);
        this.endSubmit();

    }
}

window.onload = e => {
    new Page(
        document.getElementById('table'),
        document.getElementById('form'),
        document.getElementById('btn-spinner'),
        document.getElementById('btn-text')
    );
}