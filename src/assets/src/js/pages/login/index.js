class Page extends BasePage
{
    constructor(form, messages, text, spinner)
    {
        super(form, spinner, text);
        this.messages = messages;
        this.init();

        storage.deleteToken();
    }

    init()
    {
        this.form.onsubmit(() => {
            this.messages.replaceChildren();
            this.startSubmit();

            authentication.login(this.form.jsonData())
                .then(() => {
                    alerts.success('You are being redirected...', 'Connected successfuly');
                    setTimeout(() => window.location = '/dashboard', 2000);
                    
                    this.endSubmit();
                })
                .catch(error => {
                    this.error(error);
                    this.endSubmit();
                });
        })
    }   
}

window.onload = e => {
    new Page(
        document.getElementById('form'),
        document.getElementById('messages'),
        document.getElementById('btn-text'),
        document.getElementById('btn-spinner')
    )
}