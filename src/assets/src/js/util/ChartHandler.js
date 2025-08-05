class ArrayHandler
{
    constructor(container, key)
    {
        this.container = container;
        this.key = key;
    }

    pop()
    { this.container[this.key].pop(); }

    push(data)
    { this.container[this.key].push(data); }

    replace(data)
    { this.container[this.key] = data; }
}

class ChartHandler
{
    constructor(chart)
    { this.chart = chart; }

    labels()
    { return new ArrayHandler(this.chart.data, 'labels'); }    

    dataset(label)
    {
        const index = this.chart.data.datasets.findIndex(dataset => dataset.label === label);
        if(index !== -1)
        { return new ArrayHandler(this.chart.data.datasets, index); }

        return null;
    } 
    
    datasets()
    {return new ArrayHandler(this.chart.data, 'datasets'); }

    update()
    { this.chart.update(); }
}