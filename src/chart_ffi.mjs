export function setup(data)
{
    return [{
            labels: data.labels.toArray(),
            datasets: data.datasets.toArray().map(row => {
                const {label, data} = row;
                return {
                    label,
                    data: data.toArray()
                };
            })
        },
        {
            scales: {
                y: {
                    beginAtZero: true
                }
            },
            responsive: true
        }
    ];
}