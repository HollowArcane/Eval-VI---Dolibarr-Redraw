const storage = {
    saveToken: function (token)
    { localStorage.setItem("token", token); },
    
    delete: function ()
    { localStorage.removeItem("token"); },
    
    requireToken: function ()
    {
        const token = localStorage.getItem("token");
        if(token === null)
        { throw new Error('No token registrered'); }
        return token;
    },
}