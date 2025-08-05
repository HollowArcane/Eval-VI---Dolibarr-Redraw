class MapBuilder 
{
    static MARKER_PROPERTIES = {
        'draggable': 'draggable',
        'name': 'name',
        'opacity': 'opacity'
    }

    static AREA_PROPERTIES = {
        'border': 'color',
        'background': 'fillColor',
        'alt': 'alt',
        'border-width': 'weight',
        'border-dash': 'dashArray',
        'src': 'src',
        'opacity': 'opacity'
    }

    static LEAFLET_ICONS = {};

    constructor(map)
    {
        this.map = map;
        this.mousePin = null;
        this.mouseOverlay = null;
    }

    readMarkerProperties(event)
    {
        const properties = {  };
        if(event.getAttribute('icon'))
        { properties.icon = MapBuilder.LEAFLET_ICONS[event.getAttribute('icon')]; }

        for (let key in MapBuilder.MARKER_PROPERTIES) 
        {
            let property = this.readProperty(event, key);

            if (property !== undefined && property !== null)
            { properties[MapBuilder.MARKER_PROPERTIES[key]] = property; }
        }
        return properties;
    }

    readAreaProperties(event)
    {
        const properties = {fillOpacity: 1};

        for (let key in MapBuilder.AREA_PROPERTIES) 
        {
            let property = this.readProperty(event, key);

            if (property !== undefined && property !== null)
            { properties[MapBuilder.AREA_PROPERTIES[key]] = property; }
        }
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

    updateMarkerInputs(e)
    {
        const id = this.map.getAttribute("id");
        if(id === undefined)
        { return; }

        let inputs = document.querySelectorAll(`input[target="${id}.marker.latitude"], input[target="${id}.marker.lat"], input[target="${id}.pin.latitude"], input[target="${id}.pin.lat"]`);
        for(let input of inputs)
        { input.value = e.target.getLatLng().lat; }

        inputs = document.querySelectorAll(`input[target="${id}.marker.longitude"], input[target="${id}.marker.lng"], input[target="${id}.pin.longitude"], input[target="${id}.pin.lng"]`);
        for(let input of inputs)
        { input.value = e.target.getLatLng().lng; }

        inputs = document.querySelectorAll(`input[target="${id}.marker.name"], input[target="${id}.pin.name"]`);
        for(let input of inputs)
        { input.value = e.target.options.name || ''; }
    }

    addMarkers(map)
    {
        const markers = this.map.querySelectorAll('marker, pin');
        for(let marker of markers)
        {
            const properties = this.readMarkerProperties(marker);
            const m = L.marker([
                marker.getAttribute("lat") || marker.getAttribute("latitude"),
                marker.getAttribute("lng") || marker.getAttribute("longitude")
            ], properties).addTo(map)

            const popups = marker.querySelectorAll('overlay');
            const followClick = this.readProperty(marker, 'follow-click');
            
            for(let popup of popups)
            {
                const tooltip = this.createTooltip(popup, m);;
                if(followClick)
                { this.mouseOverlay = tooltip; }
            }

            m.on('click', e => this.updateMarkerInputs(e));
            m.on('dragend', e => this.updateMarkerInputs(e));

            if(followClick)
            { this.mousePin = m; }
        }
    }

    static createArrayIfDefined(icon, keyX, keyY)
    {
        const x = icon.getAttribute(keyX);
        const y = icon.getAttribute(keyY);
        if(x && y)
        { return [parseFloat(x), parseFloat(y)]; }
    }

    static addIcons(map)
    {
        const icons = map.querySelectorAll('icon');
        for(let icon of icons)
        {
            const props = {};

            if(icon.getAttribute('src'))
            { props.iconUrl = icon.getAttribute('src'); }

            if(icon.getAttribute('shadow-src'))
            { props.shadowUrl = icon.getAttribute('shadow-src'); }

            let values = MapBuilder.createArrayIfDefined(icon, 'width', 'height');
            if(values)
            { props.iconSize = values; }

            values = MapBuilder.createArrayIfDefined(icon, 'shadow-width', 'shadow-height');
            if(values)
            { props.shadowSize = values; }
            
            values = MapBuilder.createArrayIfDefined(icon, 'anchor-x', 'anchor-y');
            if(values)
            { props.iconAnchor = values; }
            
            values = MapBuilder.createArrayIfDefined(icon, 'shadow-anchor-x', 'shadow-anchor-y');
            if(values)
            { props.shadowAnchor = values; }
            
            values = MapBuilder.createArrayIfDefined(icon, 'popup-anchor-x', 'popup-anchor-y');
            if(values)
            { props.popupAnchor = values; }

            MapBuilder.LEAFLET_ICONS[icon.getAttribute('name')] = L.icon(props);
        }
    }

    createTooltip(popup, element)
    {
        if(popup.getAttribute('type') === 'tooltip')
        {
            if (this.readProperty(popup, 'open'))
            { return element.bindTooltip(popup.innerHTML).openTooltip(); }
            
            return element.bindTooltip(popup.innerHTML);
        }

        if (this.readProperty(popup, 'open'))
        { return element.bindPopup(popup.innerHTML).openPopup(); }
        
        return element.bindPopup(popup.innerHTML);
    }

    addAreas(map)
    {
        let areas = this.map.querySelectorAll('path');
        for(let area of areas)
        {
            const props = this.readAreaProperties(area);
            const type = area.getAttribute('type');
            let layer;
            if(type === 'polygon' || type === 'polyline' || type === 'rectangle' || type === 'image')
            { layer = this.createPath(area, props, map, type); }
            else 
            { layer = this.createCircle(area, props, map); }

            const popups = area.querySelectorAll('overlay');
            for(let popup of popups)
            { this.createTooltip(popup, layer); }
        }
    }

    createPath(area, props, map, type = 'polygon')
    {
        const points = area.querySelectorAll('point');        
        if (points.length > 0)
        {
            const pts = [];
            for (let point of points)
            {
                pts.push([
                    point.getAttribute("lat") || point.getAttribute("latitude"),
                    point.getAttribute("lng") || point.getAttribute("longitude")
                ]);
            }
            
            if(type === 'polygon')
            { return L.polygon(pts, props).addTo(map); }
            else if(type === 'rectangle')
            { return L.rectangle(pts, props).addTo(map); }
            else if(type === 'image')
            { return L.imageOverlay(props.src, pts, props).addTo(map); }
            
            return L.polyline(pts, props).addTo(map);
        }
    }

    createCircle(area, props, map)
    {
        let lat = area.getAttribute("lat") || area.getAttribute("latitude");
        let long = area.getAttribute("lng") || area.getAttribute("longitude");
        let radius = area.getAttribute("radius");

        if (lat && long && radius)
            {
            return L.circle([lat, long], {
                radius: radius,
                ...props
            }).addTo(map);
        }
    }

    build()
    {
        const div = document.createElement("div");
        this.map.append(div);

        const map = L.map(div).setView([
            this.map.getAttribute("lat") || this.map.getAttribute("latitude") || 51.505,
            this.map.getAttribute("lng") || this.map.getAttribute("longitude") || -0.09
        ], this.map.getAttribute("zoom") || 13);
        L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(map);

        map.on('click', e => {
            const id = this.map.getAttribute("id");
            if(id === undefined)
            { return; }

            if(this.mousePin)
            {
                this.mousePin.setLatLng(e.latlng);
                if(this.mouseOverlay)
                {
                    this.mouseOverlay.openPopup();
                    this.mouseOverlay.openTooltip();
                }
            }

            let inputs = document.querySelectorAll(`input[target="${id}.latitude"], input[target="${id}.lat"]`);
            for(let input of inputs)
            { input.value = e.latlng.lat; }

            inputs = document.querySelectorAll(`input[target="${id}.longitude"], input[target="${id}.lng"]`);
            for(let input of inputs)
            { input.value = e.latlng.lng; }
        });

        this.addMarkers(map);
        this.addAreas(map);
    }
}

window.addEventListener('load', () => {
    const maps = document.querySelectorAll('map');
    for(const map of maps)
    { MapBuilder.addIcons(map); }
    
    for(const map of maps)
    {
        const builder = new MapBuilder(map);
        if(builder)
        { builder.build(); }
    }
})