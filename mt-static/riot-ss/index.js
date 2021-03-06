riot.tag2('ss', '<svg></svg>', '', '', function(opts) {
    var tag = this

    tag.on('mount', function (){
        var use = document.createElementNS('http://www.w3.org/2000/svg', 'use')
        var svg = tag.root.querySelector('svg')

        use.setAttributeNS(
            'http://www.w3.org/1999/xlink',
            'href',
            opts.href)

        svg.setAttribute('role', 'img')
        if(opts.title){
            svg.setAttribute('title', opts.title)
        }
        if(opts.class){
            svg.setAttribute('class', opts.class)
        }

        svg.appendChild(use)
        tag.root.parentNode.replaceChild(svg, tag.root)
    })
});

