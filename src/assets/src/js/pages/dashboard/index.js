class Page extends BasePage
{
    constructor(expenses, budgets, campaigns, form, spinner, text)
    {
        super(form, spinner, text);

        this.expenses = expenses;
        this.budgets = budgets;
        this.campaigns = campaigns;
        this.form = new FormHandler(form);

        this.init();
    }

    init()
    {
        let token = this.requireToken();

        this.form.onsubmit(e => {
            this.startSubmit();
            const formdata = this.form.formData();
            request(`/api/dashboard?date_min=${formdata.get('date-min')}&date_max=${formdata.get('date-max')}`)
                .authorize(token).get()
                .then(this.render.bind(this))
                .catch(this.error.bind(this));
        })

        request('/api/dashboard').authorize(token).get()
            .then(this.render.bind(this))
            .catch(this.error.bind(this));
    }

    render(json)
    {
        this.campaigns.textContent = json.data.campaigns.length;
        this.budgets.textContent = json.data.budgets.toLocaleString('en-US');
        this.expenses.textContent = json.data.expenses.toLocaleString('en-US');

        let labels = json.data.total_expense_per_campaign.labels;
        let datasets = json.data.total_expense_per_campaign.datasets;

        this.updateChartComparison(labels, datasets);
        this.updateChartDistribution(labels, datasets);

        labels = json.data.expense_evolution_per_campaign.labels;
        datasets = json.data.expense_evolution_per_campaign.datasets;

        this.updateChartEvolution(labels, datasets);
        this.endSubmit();
    }

    updateChartDistribution(labels, datasets)
    {
        CHARTS['chart-distribution'].data.labels = labels;

        CHARTS['chart-distribution'].data.datasets = [{
            label: 'Budget',
            data: labels.map(label => datasets.Budget[label])
        }];

        CHARTS['chart-distribution'].update();
    }

    updateChartComparison(labels, datasets)
    {
        CHARTS['chart-comparison'].data.labels = labels;
        CHARTS['chart-comparison'].data.datasets = [];
        for (let key in datasets) {
            CHARTS['chart-comparison'].data.datasets.push({
                label: key,
                data: labels.map(label => datasets[key][label])
            });
        }
        CHARTS['chart-comparison'].update();
    }

    updateChartEvolution(labels, datasets)
    {
        CHARTS['chart-evolution'].data.labels = labels;
        CHARTS['chart-evolution'].data.datasets = [];
        for (let key in datasets) {
            CHARTS['chart-evolution'].data.datasets.push({
                label: key,
                data: labels.map(label => datasets[key][label])
            });
        }
        CHARTS['chart-evolution'].update();
    }
}

window.onload = e => {
    new Page(
        document.getElementById('total-expenses'),
        document.getElementById('total-budgets'),
        document.getElementById('total-campaigns'),
        document.getElementById('form'),
        document.getElementById('btn-spinner'),
        document.getElementById('btn-text')
    );
}