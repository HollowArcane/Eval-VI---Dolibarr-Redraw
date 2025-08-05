function doGeneratePDF() {generateSalarySlipPDF(data)}

function generateSalarySlipPDF(salarySlip) {
    // Create HTML content for the salary slip
    const htmlContent = `
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Salary Slip</title>
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body {
                    font-family: 'Arial', sans-serif;
                    font-size: 12px;
                    line-height: 1.4;
                    color: #333;
                    background: white;
                    padding: 20px;
                }
                
                .salary-slip {
                    max-width: 800px;
                    margin: 0 auto;
                    border: 2px solid #2c3e50;
                    background: white;
                }
                
                .header {
                    background: linear-gradient(135deg, #2c3e50 0%, #3498db 100%);
                    color: white;
                    padding: 20px;
                    text-align: center;
                }
                
                .company-name {
                    font-size: 24px;
                    font-weight: bold;
                    margin-bottom: 5px;
                }
                
                .document-title {
                    font-size: 18px;
                    font-weight: normal;
                    opacity: 0.9;
                }
                
                .employee-info {
                    padding: 20px;
                    background: #f8f9fa;
                    border-bottom: 1px solid #e9ecef;
                }
                
                .info-row {
                    display: flex;
                    justify-content: space-between;
                    margin-bottom: 10px;
                }
                
                .info-row:last-child {
                    margin-bottom: 0;
                }
                
                .info-label {
                    font-weight: bold;
                    color: #2c3e50;
                    min-width: 120px;
                }
                
                .info-value {
                    color: #555;
                }
                
                .salary-details {
                    display: flex;
                    min-height: 300px;
                }
                
                .earnings-section,
                .deductions-section {
                    flex: 1;
                    padding: 20px;
                }
                
                .earnings-section {
                    border-right: 1px solid #e9ecef;
                }
                
                .section-title {
                    font-size: 16px;
                    font-weight: bold;
                    color: #2c3e50;
                    margin-bottom: 15px;
                    padding-bottom: 8px;
                    border-bottom: 2px solid #3498db;
                }
                
                .earnings-section .section-title {
                    color: #27ae60;
                    border-bottom-color: #27ae60;
                }
                
                .deductions-section .section-title {
                    color: #e74c3c;
                    border-bottom-color: #e74c3c;
                }
                
                .salary-item {
                    display: flex;
                    justify-content: space-between;
                    padding: 8px 0;
                    border-bottom: 1px solid #f1f2f6;
                }
                
                .salary-item:last-child {
                    border-bottom: none;
                }
                
                .component-name {
                    color: #555;
                }
                
                .component-amount {
                    font-weight: bold;
                    color: #2c3e50;
                }
                
                .earnings-section .component-amount {
                    color: #27ae60;
                }
                
                .deductions-section .component-amount {
                    color: #e74c3c;
                }
                
                .totals-section {
                    background: #f8f9fa;
                    padding: 20px;
                    border-top: 2px solid #e9ecef;
                }
                
                .totals-row {
                    display: flex;
                    justify-content: space-between;
                    margin-bottom: 10px;
                    padding: 5px 0;
                }
                
                .totals-row:last-child {
                    margin-bottom: 0;
                }
                
                .total-label {
                    font-weight: bold;
                    color: #2c3e50;
                }
                
                .total-amount {
                    font-weight: bold;
                    color: #2c3e50;
                }
                
                .net-pay-row {
                    border-top: 2px solid #2c3e50;
                    padding-top: 15px;
                    margin-top: 15px;
                }
                
                .net-pay-row .total-label,
                .net-pay-row .total-amount {
                    font-size: 18px;
                    color: #2c3e50;
                }
                
                .footer {
                    padding: 20px;
                    text-align: center;
                    background: #f8f9fa;
                    border-top: 1px solid #e9ecef;
                    font-size: 10px;
                    color: #666;
                }
                
                @media print {
                    body {
                        padding: 0;
                    }
                    
                    .salary-slip {
                        border: none;
                        box-shadow: none;
                    }
                }
            </style>
        </head>
        <body>
            <div class="salary-slip">
                <div class="header">
                    <div class="company-name">Company Name</div>
                    <div class="document-title">Salary Slip</div>
                </div>
                
                <div class="employee-info">
                    <div class="info-row">
                        <span class="info-label">Employee Name:</span>
                        <span class="info-value">${salarySlip.employee_name}</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Pay Period:</span>
                        <span class="info-value">${new Date(salarySlip.start_date).toLocaleDateString()} - ${new Date(salarySlip.end_date).toLocaleDateString()}</span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">Posting Date:</span>
                        <span class="info-value">${new Date(salarySlip.posting_date).toLocaleDateString()}</span>
                    </div>
                </div>
                
                <div class="salary-details">
                    <div class="earnings-section">
                        <div class="section-title">Earnings</div>
                        ${salarySlip.earnings.map(earning => `
                            <div class="salary-item">
                                <span class="component-name">${earning.salary_component}</span>
                                <span class="component-amount">$${earning.amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
                            </div>
                        `).join('')}
                    </div>
                    
                    <div class="deductions-section">
                        <div class="section-title">Deductions</div>
                        ${salarySlip.deductions.map(deduction => `
                            <div class="salary-item">
                                <span class="component-name">${deduction.salary_component}</span>
                                <span class="component-amount">$${deduction.amount.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
                
                <div class="totals-section">
                    <div class="totals-row">
                        <span class="total-label">Total Earnings:</span>
                        <span class="total-amount">$${salarySlip.earnings.reduce((sum, earning) => sum + earning.amount, 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
                    </div>
                    <div class="totals-row">
                        <span class="total-label">Total Deductions:</span>
                        <span class="total-amount">$${salarySlip.deductions.reduce((sum, deduction) => sum + deduction.amount, 0).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
                    </div>
                    <div class="totals-row net-pay-row">
                        <span class="total-label">Net Pay:</span>
                        <span class="total-amount">$${salarySlip.net_pay.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
                    </div>
                </div>
                
                <div class="footer">
                    <p>This is a computer-generated salary slip and does not require a signature.</p>
                    <p>Generated on ${new Date().toLocaleDateString()} at ${new Date().toLocaleTimeString()}</p>
                </div>
            </div>
        </body>
        </html>
    `;

    // Configure html2pdf options
    const options = {
        margin: 0.2,
        filename: `salary_slip_${salarySlip.employee_name.replace(/\s+/g, '_').toLowerCase()}.pdf`,
        image: { type: 'jpeg', quality: 0.98 },
        html2canvas: { 
            scale: 2,
            useCORS: true,
            letterRendering: true
        },
        jsPDF: { 
            unit: 'in', 
            format: 'a4', 
            orientation: 'portrait' 
        }
    };

    // Generate and download the PDF
    html2pdf()
        .set(options)
        .from(htmlContent)
        .outputPdf('blob')
        .then((pdfBlob) => {
            // Create a blob URL for the PDF
            const pdfUrl = URL.createObjectURL(pdfBlob);
            
            // Open the PDF in a new tab
            const newTab = window.open(pdfUrl, '_blank');
            
            if (newTab) {
                console.log('PDF opened in new tab successfully!');
                
                // Optional: Clean up the blob URL after some time to free memory
                setTimeout(() => {
                    URL.revokeObjectURL(pdfUrl);
                }, 10000); // Clean up after 10 seconds
            } else {
                console.warn('Unable to open new tab. Pop-up blocker might be active.');
                // Fallback: create download link
                const link = document.createElement('a');
                link.href = pdfUrl;
                link.download = options.filename;
                link.textContent = 'Download PDF';
                document.body.appendChild(link);
                link.click();
                document.body.removeChild(link);
                URL.revokeObjectURL(pdfUrl);
            }
        })
        .catch((error) => {
            console.error('Error generating PDF:', error);
        });
}

// Helper function to format currency values
function formatCurrency(amount) {
    if (amount === null || amount === undefined) return '0.00';
    return parseFloat(amount).toLocaleString('en-US', {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
    });
}

// Helper function to format dates
function formatDate(dateString) {
    if (!dateString) return 'N/A';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
}

// Helper function to format date for filename (YYYY-MM-DD)
function formatDateForFilename(dateString) {
    if (!dateString) return 'unknown';
    const date = new Date(dateString);
    return date.toISOString().split('T')[0];
}

// Example usage:
/*
const sampleSalarySlip = {
    name: "SalarySlip001",
    employee: "EMP001",
    employee_name: "John Doe",
    company: "ABC Corporation",
    posting_date: "2024-01-31",
    status: "Submitted",
    currency: "USD",
    start_date: "2024-01-01",
    end_date: "2024-01-31",
    salary_structure: "Monthly Salary",
    total_working_hours: 160.0,
    base_hour_rate: 25.0,
    net_pay: 3500.0,
    rounded_total: 3500.0,
    total_in_words: "Three Thousand Five Hundred Dollars Only",
    ctc: 4200.0,
    income_from_other_sources: 0.0
};

// Call the function
generateSalarySlipPDF(sampleSalarySlip);
*/