class ChartBuilderFactory
{
    static PROPERTIES = {
        'background': 'backgroundColor',
        'border': 'borderColor',
        'border-width': 'borderWidth',
        'background:hover': 'hoverBackgroundColor',
        'border:hover': 'hoverBorderColor',
        'border-width:hover': 'hoverBorderWidth',
        'pt-background': 'pointBackgroundColor',
        'pt-border': 'pointBorderColor',
        'pt-border-width': 'pointBorderWidth',
        'pt-background:hover': 'pointHoverBackgroundColor',
        'pt-border:hover': 'pointHoverBorderColor',
        'pt-border-width:hover': 'pointHoverBorderWidth'
    }

    static createBuilder(chart)
    {
        switch(chart.getAttribute('type'))
        {
            case 'line':
                return new LineChartBuilder(chart);
            case 'bar':
                return new BarChartBuilder(chart);
            case 'pie':
                return new PieChartBuilder(chart);
            case 'doughnut':
                return new DoughnutChartBuilder(chart);
            default:
                return null;
        }
    }

    static parseValue(value)
    {
        try
        { return parseFloat(value); }
        catch (error)
        { return null; }
    }

    static createImagePlugin(imageConsumer)
    {
        return (chart, args, option) => {
            const { ctx } = chart;

            ctx.save();
            const images = option.images || [];
            const widths = option.imageWidths || 100;

            for(let i = 0; i < images.length; i++)
            {
                chart.getDatasetMeta(i).data.forEach((datapoint, index) => {
                    const image = new Image();
                    image.src = images[i][index] || '';
                    const height = image.height * widths[i] / image.width;

                    console.log(image.src);
                    imageConsumer(ctx, datapoint, image, widths[i], height);
                });
            }
            ctx.restore();
        };
    }

    static getProperty(property, dataset, datas, flatten = true)
    {
        let parent = dataset.getAttribute(property);
        let properties = [], valid = false;

        for(let data of datas)
        {
            properties.push(data.getAttribute(property) || parent);
            if(properties[properties.length - 1])
            { valid = true; }
        }

        if(flatten && properties.length > 0 && properties.every(item => item === properties[0]))
        { properties = properties[0]; }

        return valid ? properties: null;
    }

    static splitValues(attribute)
    {
        const values = [];
        let j = 0, depth = 0;
        for(let i = 0; i < attribute.length; i++)
        {
            if(attribute[i] === '(')
            { depth++; }
            
            if(attribute[i] === ')')
            { depth--; }

            if(attribute[i] === ',' && depth === 0)
            {
                values.push(attribute.substring(j, i).trim());
                j = i+1;
            }
        }
        values.push(attribute.substring(j, attribute.length));
        return values;
    }

    static gradientFill(angle, context, colors)
    {
        if(!context.chart.chartArea)
        { return; }

        angle = angle * Math.PI / 180;
        const { ctx, chartArea: { top, bottom, left, right } } = context.chart;
        let cos = Math.cos(angle), sin = Math.sin(angle);

        let w = (right - left), h = (bottom - top);
        let cx = left + w / 2, cy = top + h / 2;
        let stepx = w / 2 * sin / cos, stepy = h / 2 * cos / sin;

        const gradient =
            sin === 0 && cos > 0 ? ctx.createLinearGradient(left, 0, right, 0):
            sin === 0 && cos < 0 ? ctx.createLinearGradient(right, 0, left, 0):
            sin > 0 && cos === 0 ? ctx.createLinearGradient(0, top, 0, bottom):
            sin < 0 && cos === 0 ? ctx.createLinearGradient(0, bottom, 0, top):
            ctx.createLinearGradient(cx - stepx, cy - stepy, cx + stepx, cy + stepy);
        const delta = 1/(colors.length - 1);

        for(let i = 0; i < colors.length; i++)
        { gradient.addColorStop(i * delta, colors[i]); }
        
        return gradient;
    }

    static extractFunction(attribute)
    {
        if(!attribute)
        { return null; }

        for(let i = 0; i < attribute.length; i++)
        {
            if(attribute[i] === '(')
            {
                return {
                    name: attribute.substring(0, i),
                    values: ChartBuilderFactory.splitValues(attribute.substring(i + 1, attribute.length - 1))
                };
            }
        }
        return null;
    }
}

class ChartBuilder
{
    /**
     * Create a new default chart builder of the specified type from the specified chart.
     * @constructor
     * @param {string} type - The type of the book.
     * @param {Node} chart - The HTML node to create the chart from.
     */
    constructor(type, chart)
    {
        this.type = type;
        this.chart = chart;
        this.canvas = document.createElement('canvas');
        this.labels = [];
        this.datasets = [];
        this.padding = chart.getAttribute('padding') || 0;
        this.images = [];
        this.imageWidths = [];
    }

    addLabels()
    {
        const labels = this.chart.querySelector('labels');

        for(let label of labels.querySelectorAll('label'))
        { this.labels.push(label.textContent); }
    }

    addDatasets()
    {
        for(let dataset of this.chart.querySelectorAll('dataset'))
        { this.datasets.push(this.createDatasetConfig(dataset)); }
    }

    createDatasetConfig(dataset)
    {
        const datasetConfig = {
            label: dataset.getAttribute('name'),
            data: []
        };

        const datas = dataset.querySelectorAll('data');
        for (let i = 0; i < datas.length; i++)
        { datasetConfig.data.push(ChartBuilderFactory.parseValue(datas[i].textContent)); }
        
        this.readProperties(dataset, datas, datasetConfig);
        return datasetConfig;
    }

    readProperties(dataset, datas, datasetConfig)
    {
        for (let key in ChartBuilderFactory.PROPERTIES) 
        {
            let properties = ChartBuilderFactory.getProperty(key, dataset, datas);
            if (properties)
            { datasetConfig[ChartBuilderFactory.PROPERTIES[key]] = properties; }
        }

        let images = ChartBuilderFactory.getProperty('img', dataset, datas, false);
        this.images.push(images || []);

        this.imageWidths.push(dataset.getAttribute('img-width') || 100);

        let fx = ChartBuilderFactory.extractFunction(dataset.getAttribute('background'));
        if(fx && fx.name == 'linear-gradient')
        {
            const angle = fx.values.shift();
            const colors = fx.values;
            datasetConfig.backgroundColor = ctx => ChartBuilderFactory.gradientFill(angle, ctx, colors);
        }

        fx = ChartBuilderFactory.extractFunction(dataset.getAttribute('border'));
        if(fx && fx.name == 'linear-gradient')
        {
            const angle = fx.values.shift();
            const colors = fx.values;
            datasetConfig.borderColor = ctx => ChartBuilderFactory.gradientFill(angle, ctx, colors);
        }
    }

    createContainer()
    {
        const container = document.createElement('div');
        container.append(this.canvas);
        return container;
    }

    getPlugins()
    { return []; }

    getPluginOptions()
    { return {}; }

    build()
    {
        this.addLabels();
        this.addDatasets();

        return new Chart(this.canvas, {
            type: this.type,
            data: {
                labels: this.labels,
                datasets: this.datasets
            },
            options: {
                plugins: this.getPluginOptions(),
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        grace: this.padding
                    }
                }
            },
            plugins: this.getPlugins()
        });
    }
}

class LineChartBuilder extends ChartBuilder
{
    static LINE_IMAGE = {
        id: 'LINE_IMAGE',
        afterDatasetDraw: ChartBuilderFactory.createImagePlugin(
            (ctx, data, img, w, h) => ctx.drawImage(img,
                data.x - w/2,
                data.y - h - 10,
                w, h
            )
        )
    };

    constructor(chart)
    { super('line', chart); }

    createDatasetConfig(dataset)
    {
        const datasetConfig = super.createDatasetConfig(dataset);

        if (dataset.getAttribute('tension'))
        { datasetConfig.tension = dataset.getAttribute('tension'); }

        if(datasetConfig.backgroundColor)
        { datasetConfig.fill = true; }

        return datasetConfig;
    }

    getPluginOptions()
    {
        return {
            LINE_IMAGE: {
                images: this.images,
                imageWidths: this.imageWidths
            }
        };
    }

    getPlugins()
    { return [ LineChartBuilder.LINE_IMAGE ]; }

}

class BarChartBuilder extends ChartBuilder
{
    static BAR_IMAGE = {
        id: 'BAR_IMAGE',
        afterDatasetDraw: ChartBuilderFactory.createImagePlugin(
            (ctx, data, img, w, h) => ctx.drawImage(img,
                data.x - w/2,
                data.y - h,
                w, h
            )
        )
    };

    constructor(chart)
    { super('bar', chart); }

    getPluginOptions()
    {
        return {
            BAR_IMAGE: {
                images: this.images,
                imageWidths: this.imageWidths
            }
        };
    }

    getPlugins()
    { return [ BarChartBuilder.BAR_IMAGE ]; }
}

class DoughnutChartBuilder extends ChartBuilder
{
    static DOUGHNUT_IMAGE = {
        id: 'DOUGHNUT_IMAGE',
        afterDatasetDraw: ChartBuilderFactory.createImagePlugin(
            (ctx, data, img, w, h) => ctx.drawImage(img,
                data.tooltipPosition().x - w/2,
                data.tooltipPosition().y - h/2,
                w, h
            )
        )
    };

    constructor(chart)
    { super('doughnut', chart); }

    getPluginOptions()
    {
        return {
            DOUGHNUT_IMAGE: {
                images: this.images,
                imageWidths: this.imageWidths
            }
        };
    }

    getPlugins()
    { return [ DoughnutChartBuilder.DOUGHNUT_IMAGE ]; }
}

class PieChartBuilder extends ChartBuilder
{
    static PIE_IMAGE = {
        id: 'PIE_IMAGE',
        afterDatasetDraw: ChartBuilderFactory.createImagePlugin(
            (ctx, data, img, w, h) => ctx.drawImage(img,
                data.tooltipPosition().x - w/2,
                data.tooltipPosition().y - h/2,
                w, h
            )
        )
    };

    constructor(chart)
    { super('pie', chart); }

    getPluginOptions()
    {
        return {
            PIE_IMAGE: {
                images: this.images,
                imageWidths: this.imageWidths
            }
        };
    }

    getPlugins()
    { return [ PieChartBuilder.PIE_IMAGE ]; }
}


window.addEventListener('load', () => {
    const charts = document.querySelectorAll('chart');

    for(const chart of charts)
    {
        const builder = ChartBuilderFactory.createBuilder(chart);
        if(builder)
        {
            chart.append(builder.createContainer());
            builder.build();
        }

    }
})