import { is_null } from "../gleam_stdlib/gleam_stdlib.mjs";
import html2pdf from 'html2pdf.js';
import { pdf_to_string } from './util/export.mjs'

function generateHTMLList(title, data) {
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
			const value = pdf_to_string(field[1]);
			recordMap[field[0]] = value;
		});

		// Add data for each field
		fieldNames.forEach(fieldName => {
			const value = recordMap[fieldName] || '';
			tableHTML += `<td>${value}</td>`;
		});

		tableHTML += '</tr>';
	});
	tableHTML += '</tbody></table>';

	return `<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${title}</title>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/html2pdf.js/0.10.1/html2pdf.bundle.min.js"></script>
        <style>
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
                border: 1px solid #e0e0e0;
                border-bottom: 2px solid #f0f0f0;
                padding: 12px 8px;
                font-weight: 600;
                color: #34495e;
                font-size: 14px;
                flex: 1;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                margin-bottom: 5px;
            }
            
            .data-table td {
                border: 1px solid #e0e0e0;
            
                padding: 10px 8px;
                vertical-align: top;
            }
            
            body {
                font-family: Arial, sans-serif;
                margin: 10px;
                background-color: #f5f5f5;
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


function generateHTMLCard(title, data) {
	let container = '';

	data.forEach(([fieldName, values]) => {
		let valueContent;

		// console.log(fieldName, values)
		// Single value
		const value = pdf_to_string(values);
		valueContent = `<div class="field-value">${value}</div>`;

		const fieldRowHTML = `
            <div class="field-row">
                <div class="field-label">${fieldName}</div>
                ${valueContent}
            </div>
        `;

		if (fieldName.trim() != "") { container += fieldRowHTML; }
	});
	return `<!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${title}</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }

            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background-color: #f5f5f5;
                padding: 20px;
            }

            .card {
                background: white;
                border-radius: 12px;
                padding: 30px;
                max-width: 600px;
                margin: 0 auto;
                box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
                border: 1px solid #e0e0e0;
            }

            .card-header {
                text-align: center;
                margin-bottom: 30px;
                padding-bottom: 20px;
                border-bottom: 2px solid #f0f0f0;
            }

            .card-title {
                font-size: 24px;
                font-weight: 600;
                color: #2c3e50;
                margin-bottom: 5px;
            }

            .card-subtitle {
                font-size: 14px;
                color: #7f8c8d;
            }

            .data-section {
                margin-bottom: 20px;
            }

            .field-row {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 12px 0;
                border-bottom: 1px solid #f8f9fa;
            }

            .field-row:last-child {
                border-bottom: none;
            }

            .field-label {
                font-weight: 600;
                color: #34495e;
                font-size: 14px;
                flex: 1;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }

            .field-value {
                font-size: 16px;
                color: #2c3e50;
                flex: 2;
                text-align: right;
                font-weight: 500;
            }

            .field-value.multiple {
                text-align: right;
            }

            .value-item {
                display: inline-block;
                background: #e8f4fd;
                color: #1976d2;
                padding: 4px 8px;
                border-radius: 4px;
                margin: 2px;
                font-size: 14px;
            }

            .card-footer {
                margin-top: 30px;
                padding-top: 20px;
                border-top: 2px solid #f0f0f0;
                text-align: center;
                font-size: 12px;
                color: #95a5a6;
            }

            /* Print styles for PDF generation */
            @media print {
                body {
                    background: white;
                    padding: 0;
                }
                
                .card {
                    box-shadow: none;
                    border: 1px solid #ddd;
                    margin: 0;
                    max-width: none;
                }
            }

            /* Responsive design */
            @media (max-width: 768px) {
                .field-row {
                    flex-direction: column;
                    align-items: flex-start;
                }
                
                .field-label {
                    margin-bottom: 8px;
                }
                
                .field-value {
                    text-align: left;
                }
            }
        </style>
    </head>
    <body>
        <div class="card">
            <div class="card-header">
                <h1 class="card-title">${title}</h1>
                <p class="card-subtitle">Absolute Omega <span id="current-date"></span></p>
            </div>

            <div class="data-section" id="data-container">${container}</div>

            <div class="card-footer">
                <p>StockAsap All Rights Reserved - &copy Copyright 2025 - Ω </p>
            </div>
        </div>
    </body>
    </html>`;
}

function generatePDF(element) {
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

export function generateCard(title, data) {
	data = data.toArray();

	if (data.length === 0) {
		return;
	}

	const element = generateHTMLCard(title, data);
	generatePDF(element)
}

export function generateTable(title, data) {
	data = data.toArray().map(row => row.toArray());

	if (data.length === 0) {
		return;
	}

	const element = generateHTMLList(title, data);
	generatePDF(element)
}
