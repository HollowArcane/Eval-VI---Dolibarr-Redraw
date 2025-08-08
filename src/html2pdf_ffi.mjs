import { is_null } from "../gleam_stdlib/gleam_stdlib.mjs";
import * as $stdlib from "./gleam.mjs";
import html2pdf from 'html2pdf.js';

function generateHTML(title, data) {
    if (data.length === 0) {
        return;
    }

    let tableHTML = '<table class="data-table">';
    
    // Extract all unique field names for header
    const allFields = new Set();
    data.forEach(record => {
        record.forEach(field => {
            allFields.add(field[0]);
        });
    });
    
    const fieldNames = Array.from(allFields);
    
    // Create header
    tableHTML += '<thead><tr>';
    fieldNames.forEach(fieldName => {
        tableHTML += `<th>${fieldName}</th>`;
    });
    tableHTML += '</tr></thead>';
    
    // Create rows
    tableHTML += '<tbody>';
    data.forEach((record, index) => {
        tableHTML += '<tr>';
        
        // Create a map of field name to value for this record
        const recordMap = {};
        record.forEach(field => {
            const value = field[1][0].content
            recordMap[field[0]] = is_null(value) ? field[1][0]: value; // Get first value from array
        });
        
        // Add data for each field
        fieldNames.forEach(fieldName => {
            const value = recordMap[fieldName] || '';
            tableHTML += `<td>${value}</td>`;
        });
        
        tableHTML += '</tr>';
    });
    tableHTML += '</tbody></table>';
    
    return  `<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${title}</title>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 20px;
                background-color: #f5f5f5;
            }
            
            .container {
                max-width: 1200px;
                margin: 0 auto;
                background: white;
                padding: 20px;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }
            
            h1 {
                color: #333;
                text-align: center;
                margin-bottom: 30px;
            }
            
            .controls {
                margin-bottom: 30px;
                text-align: center;
            }
            
            button {
                background: #007bff;
                color: white;
                border: none;
                padding: 12px 24px;
                border-radius: 5px;
                cursor: pointer;
                font-size: 16px;
                margin: 0 10px;
                transition: background-color 0.3s;
            }
            
            button:hover {
                background: #0056b3;
            }
            
            .pdf-content {
                background: white;
                padding: 20px;
                margin: 20px 0;
            }
            
            .pdf-title {
                font-size: 24px;
                font-weight: bold;
                text-align: center;
                margin-bottom: 20px;
                color: #333;
            }
            
            .data-table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 20px;
            }
            
            .data-table th {
                background-color: #f8f9fa;
                border: 1px solid #dee2e6;
                padding: 12px 8px;
                text-align: left;
                font-weight: bold;
                color: #495057;
            }
            
            .data-table td {
                border: 1px solid #dee2e6;
                padding: 10px 8px;
                vertical-align: top;
            }
            
            .data-table tr:nth-child(even) {
                background-color: #f8f9fa;
            }
            
            .record-header {
                background-color: #007bff !important;
                color: white !important;
                font-weight: bold;
            }
            
            .field-name {
                font-weight: bold;
                color: #495057;
            }
            
            .field-value {
                color: #6c757d;
            }
            
            .sample-data {
                background: #e9ecef;
                padding: 15px;
                border-radius: 5px;
                margin: 20px 0;
                font-family: monospace;
                font-size: 14px;
                overflow-x: auto;
            }
            
            .info {
                background: #d1ecf1;
                border: 1px solid #bee5eb;
                color: #0c5460;
                padding: 15px;
                border-radius: 5px;
                margin: 20px 0;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div id="pdfContent" class="pdf-content">
                <div class="pdf-title">${title}</div>
                <div id="tableContainer">
                    ${tableHTML}
                </div>
            </div>
        </div>
    </body>
    </html>`;
}

function generatePDF(title, data) {
    if (data.length === 0) {
        return;
    }

    const element = generateHTML(title, data);
    const opt = {
        margin: 1,
        filename: 'data-report.pdf',
        image: { type: 'jpeg', quality: 0.98 },
        html2canvas: { scale: 2 },
        jsPDF: { unit: 'in', format: 'letter', orientation: 'portrait' }
    };

    // Generate PDF and open in new tab
    html2pdf().set(opt).from(element).toPdf().get('pdf').then(function (pdf) {
        const blob = pdf.output('blob');
        const url = URL.createObjectURL(blob);
        window.open(url, '_blank');
    });
}

export function generateTable(title, data)
{
    data = data.toArray().map(row => row.toArray());
    generatePDF(title, data);
}