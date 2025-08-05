const authentication = {
    login: async function (credentials)
    {
        const json = await request('/api').json(credentials).post();
        const token = json.data.user.access_token
        if(token)
        {
            storage.saveToken(token);
            return token;
        }
        throw new Exception("Token not found");
    }
};