class CalendarBuilderFactory
{
    static PROPERTIES = {
        'start': 'start',
        'end': 'end',
        'all-day': 'allDay',
        'background': 'backgroundColor',
        'border': 'borderColor',
        'color': 'textColor',
        'href': 'url',
        'group': 'groupId',
        'display': 'display',
        'constraint': 'constraint',
        'overlap': 'overlap',
        'max-event': 'dayMaxEvents'
    }

    static PROPERTIES_EX = {
        'clickable': 'clickable',
        'name': 'name'
    }

    static TYPES = {
        'timeline': 'timeline',
        'list': 'list',
        'grid': 'grid',
        'multiple': 'multi'
    }

    static SCALE = {
        'time': 0, 'day': 1, 'week': 3,'month': 4,'year': 5,
    }
    static SCALE_REVERSE = [ 'time', 'day', 'week', 'month', 'year' ]

    static DEFAULT_TRACK_BY = {
        'timeline': 'time',
        'list': 'time',
        'grid': 'day',
        'multiple': 'month',
    }

    static DEFAULT_TRACK_OVER = {
        'timeline': 'day',
        'list': 'week',
        'grid': 'month',
        'multiple': 'year'
    }

    static formatDate(date)
    {
        if(date === undefined || date === null)
        { return null; }

        const yyyy = date.getFullYear();
        const MM = String(date.getMonth() + 1).padStart(2, '0'); // Months are 0-based
        const dd = String(date.getDate()).padStart(2, '0');
        const hh = String(date.getHours()).padStart(2, '0');
        const mm = String(date.getMinutes()).padStart(2, '0');
        const ss = String(date.getSeconds()).padStart(2, '0');
        
        return `${yyyy}-${MM}-${dd}T${hh}:${mm}:${ss}`;
    }

    static setInputValues(inputs, date)
    {
        for(let input of inputs)
        {
            if(input.getAttribute('type') === 'date' && date !== null)
            {input.value = date.split('T')[0]; }

            else
            { input.value = date; }
        }
    }
}

class CalendarBuilder
{
    constructor(calendar)
    {
        this.calendar = calendar;
        this.canvas = document.createElement('div');
        
        this.calendar.append(this.canvas);
    }

    readProperties(event)
    {
        const properties = {extendedProps: {}};

        for (let key in CalendarBuilderFactory.PROPERTIES) 
        {
            let property = this.readProperty(event, key);

            if (property !== undefined && property !== null)
            { properties[CalendarBuilderFactory.PROPERTIES[key]] = property; }
        }

        for (let key in CalendarBuilderFactory.PROPERTIES_EX) 
        {
            let property = this.readProperty(event, key);

            if (property !== undefined && property !== null)
            { properties.extendedProps[CalendarBuilderFactory.PROPERTIES_EX[key]] = property; }
        }

        properties.title = event.textContent;
        return properties;
    }

    readProperty(event, key)
    {
        let property = event.getAttribute(key);

        if (property === '' || property === 'true')
        { property = true; } 

        if (property === 'false')
        { property = false; } 

        return property;
    }

    capitalize(text)
    { return text.charAt(0).toUpperCase() + text.slice(1); }

    defaultTrackOver(trackBy, type)
    {
        const trackOver = CalendarBuilderFactory.DEFAULT_TRACK_OVER[type];
        
        if(CalendarBuilderFactory.SCALE[trackOver] <= CalendarBuilderFactory.SCALE[trackBy]
        && trackBy < CalendarBuilderFactory.SCALE['year'])
        { return CalendarBuilderFactory.SCALE_REVERSE[CalendarBuilderFactory.SCALE[trackBy] + 1]; }

        return trackOver;
    }

    buildType(type, trackBy, trackOver)
    {
        type == type || 'grid';
        if(type !== 'list' && type !== 'grid' && type !== 'multiple' && type !== 'timeline')
        { return; }

        trackBy = trackBy || CalendarBuilderFactory.DEFAULT_TRACK_BY[type];
        trackOver = trackOver || this.defaultTrackOver(trackBy, type);

        if(CalendarBuilderFactory.SCALE[trackOver] <= CalendarBuilderFactory.SCALE[trackBy])
        { trackOver = CalendarBuilderFactory.SCALE['year'];}

        if(type === 'list')
        { return 'list' + this.capitalize(trackOver); }

        if(type === 'grid')
        { return trackBy + 'Grid' + this.capitalize(trackOver); }

        if(type === 'timeline')
        { return 'resourceTimeline' + (trackOver === 'week' ? this.capitalize(trackOver): ''); }

        if(type === 'multiple')
        { return 'multiMonthYear'; }
    }

    updateEventInput(clickable, id, info)
    {
        if(!id || !info.event || !clickable && !info.event.extendedProps.clickable)
        { return; }

        let inputs = document.querySelectorAll(`input[target="${id}.event"], input[target="${id}.event.start"]`);
        CalendarBuilderFactory.setInputValues(inputs, CalendarBuilderFactory.formatDate(info.event.start));
        
        inputs = document.querySelectorAll(`input[target="${id}.event.end"]`);
        CalendarBuilderFactory.setInputValues(inputs, CalendarBuilderFactory.formatDate(info.event.end));
        
        inputs = document.querySelectorAll(`input[type="text"][target="${id}.event.title"]`);
        CalendarBuilderFactory.setInputValues(inputs, info.event.title);
        
        inputs = document.querySelectorAll(`input[type="text"][target="${id}.event.group"]`);
        CalendarBuilderFactory.setInputValues(inputs, info.event.groupId);
        
        inputs = document.querySelectorAll(`input[type="text"][target="${id}.event.name"]`);
        CalendarBuilderFactory.setInputValues(inputs, info.event.extendedProps.name || '');
    }

    build()
    {
        const DOMevents = this.calendar.querySelectorAll('events event');
        const events = [];
        
        for(let event of DOMevents)
        { events.push(this.readProperties(event)); }

        const DOMresources = this.calendar.querySelectorAll('resources resource');
        const resources = [];
        
        for(let resource of DOMresources)
        { resources.push({ title: resource.textContent }); }
        
        const type = this.buildType(
            this.calendar.getAttribute('type'),
            this.calendar.getAttribute('track-by'),
            this.calendar.getAttribute('track-over')
        );
        
        const eventClickable = this.readProperty(this.calendar, 'event-clickable');
        const clickable = this.readProperty(this.calendar, 'clickable');

        const calendarInfo = {
            initialView: type,
            events: events,
            eventClick: info => this.updateEventInput(eventClickable, this.calendar.getAttribute('id'), info),
            eventDrop: info => this.updateEventInput(eventClickable, this.calendar.getAttribute('id'), info),
            dateClick: info => {
                if(!clickable)
                { return; }

                const id = this.calendar.getAttribute('id');
                if(!id)
                { return; }

                let inputs = document.querySelectorAll(`input[target="${id}"], input[target="${id}.date"]`);
                CalendarBuilderFactory.setInputValues(inputs, CalendarBuilderFactory.formatDate(info.date));
            },
            
            resources: resources,
            selectable: this.readProperty(this.calendar, 'selectable'),
            editable: this.readProperty(this.calendar, 'editable'),
            nowIndicator: this.readProperty(this.calendar, 'indicated'),
            select: info => {
                const id = this.calendar.getAttribute('id');
                if(!id)
                { return; }

                let inputs = document.querySelectorAll(`input[target="${id}"], input[target="${id}.start"]`);
                CalendarBuilderFactory.setInputValues(inputs, CalendarBuilderFactory.formatDate(info.start));
                
                inputs = document.querySelectorAll(`input[target="${id}.end"]`);
                CalendarBuilderFactory.setInputValues(inputs, CalendarBuilderFactory.formatDate(info.end));
                
                if(!info.resource)
                { return; }

                inputs = document.querySelectorAll(`input[type="text"][target="${id}.resource"]`);
                CalendarBuilderFactory.setInputValues(inputs, info.resource.title);
            }
        };
        
        return new FullCalendar.Calendar(this.canvas, calendarInfo);
    }
}

window.addEventListener('load', () => {
    const calendars = document.querySelectorAll('calendar');
    for(const calendar of calendars) {
        const builder = new CalendarBuilder(calendar);
        if(builder)
        { builder.build().render(); }
    }
})