class Pagination
{
    constructor(container, nodeTemplate, npage, callback, spread = 1, side = 2)
    {
        this.container = container
        this.template = nodeTemplate;
        this.npage = npage;
        this.spread = spread;
        this.side = 2;
        this.callback = callback;
    }

    init()
    {
        this.setActive(1);
    }

    clamp(value, v1, v2)
    {
        return Math.min(Math.max(v1, v2), Math.max(value, Math.min(v1, v2)))
    }

    createPage(page)
    {
        const element = this.template.cloneNode(true);
        const slots = element.querySelectorAll('.slot');
        for(const slot of slots)
        { slot.textContent = page; }
        return element;
    }

    setActive(page)
    {
        const cstrActive = this.clamp(page, this.spread + 1, this.npage - this.spread);
        const max = Math.min(cstrActive + this.spread + 1 + this.side, this.npage);
        const min = Math.max(cstrActive - this.spread - 1 - this.side, 1);

        const length = max - min + 1;
        const pages = Array(length).fill(null);

        for(let i = 0; i < this.side && i < this.npage; i++)
        {
            pages[i] = this.createPage(i + 1);
            pages[length - i - 1] = this.createPage(this.npage - i);
        }

        const start = Math.max(cstrActive - min - this.spread, 0);
        const finish = Math.min(cstrActive - min + this.spread, length - 1);

        for(let i = start; i <= finish; i++)
        { pages[i] = this.createPage(i + min); }

        if(start + min === this.side + 2)
        { pages[this.side] = this.createPage(this.side + 1); }

        if(finish + min === this.npage - this.side - 1)
        { pages[length - this.side - 1] = this.createPage(this.npage - this.side); }

        if(length > this.side)
        {
            if(pages[this.side] === null)
            {
                pages[this.side] = this.createPage('...');
                pages[this.side].classList.add('disabled');
            }
        
            if(pages[length - this.side - 1] === null)
            {
                pages[length-  this.side - 1] = this.createPage('...');
                pages[this.side].classList.add('disabled');
            }
        }
        this.container.replaceChildren();
        for(const element of pages)
        {
            if(parseInt(element.textContent) === page)
            { element.classList.add('active'); }
            element.onclick = () => {
                const page = parseInt(element.textContent);
                this.callback(page);
                this.setActive(page);
            };
            this.container.append(element);
        }
    }
}