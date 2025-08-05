class BasePage
{
    constructor(form, spinner, text)
    {
        this.form = new FormHandler(form);
        this.spinner = spinner;
        this.text = text;
    }

    error(data)
    {
        alerts.error(data.message)
        console.error(data);
    }

    
    startSubmit()
    {
        this.form.disableButtons();
        this.spinner.classList.remove('d-none');
        this.text.classList.add('d-none');
    }

    endSubmit()
    {
        this.form.enableButtons();
        
        this.spinner.classList.add('d-none');
        this.text.classList.remove('d-none');
    }

    requireToken()
    {
        let token = null;
        try
        { token = storage.requireToken(); }
        catch (e)
        {
            alerts.error('Missing authentication token');
            setTimeout(() => window.location = '/', 2000);
        }
        return token;
    }
}