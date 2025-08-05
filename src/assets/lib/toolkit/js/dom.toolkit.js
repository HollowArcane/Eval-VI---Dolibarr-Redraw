function tag(tag, attributes, children)
{
    const element = document.createElement(tag);
    for(let key in attributes)
    {
        if(key.startsWith('on'))
        { element.addEventListener(key.substring(2), attributes[key]); }

        else if(attributes[key] === true)
        { element.setAttribute(key, true); }

        else if(attributes[key] !== false)
        { element.setAttribute(key, attributes[key]); }
    }
    for(const child of children)
    {
        element.appendChild(child);
    }
    return element;
}

function text(content)
{
    return document.createTextNode(content);
}

function icon(attribute, names)
{
    const icon = tag('i', attribute, []);
    for(const name of names)
    { icon.classList.add(name); }
    return icon;
}