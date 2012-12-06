### Interface to InterMine Widgets.###

# For our purposes, `$` means jQuery or Zepto.
$ = window.jQuery or window.Zepto

# Public interface for the various InterMine Widgets.
class Widgets

    VERSION: #@+VERSION

    wait:    true

    # JavaScript libraries as resources. Will be loaded if not present already.
    resources: [
        name:  'JSON'
        path:  'http://cdn.intermine.org/js/json3/3.2.2/json3.min.js'
        type:  'js'
    ,
        name:  "jQuery"
        path:  "http://cdn.intermine.org/js/jquery/1.7.2/jquery.min.js"
        type:  "js"
        wait:  true
    ,
        name:  "_"
        path:  "http://cdn.intermine.org/js/underscore.js/1.3.3/underscore-min.js"
        type:  "js"
        wait:  true
    ,
        name:  "Backbone"
        path:  "http://cdn.intermine.org/js/backbone.js/0.9.2/backbone-min.js"
        type:  "js"
        wait:  true
    ,
        name:  "google"
        path:  "https://www.google.com/jsapi"
        type:  "js"
    ,
        path:  "http://cdn.intermine.org/js/intermine/imjs/latest/imjs.js"
        type:  "js"
    ,
        path:  "http://cdn.intermine.org/css/bootstrap/2.0.4/js/bootstrap.min.js"
        type:  "js"
    ]

    ###
    New Widgets client.
    @param {string} service A string pointing to service endpoint e.g. http://aragorn:8080/flymine/service/
    @param {string} token A string for accessing user's lists.
    or
    @param {Object} opts Config just like imjs consumes e.g. `{ "root": "", "token": "" }`
    ###
    constructor: (opts...) ->
        if typeof opts[0] is 'string'
            # Assuming a service.
            @service = opts[0]
            # Do we have a token?
            @token = opts[1] or ''
        else
            # Assuming an object.
            if opts[0].root?
                @service = opts[0].root
            else
                throw Error 'You need to set the `root` parameter pointing to the mine\'s service'
            # Do we have a token?
            @token = opts[0].token or ''

        intermine.load @resources, =>
            # All libraries loaded, welcome jQuery, export classes.
            $ = window.jQuery
            # Enable Cross-Origin Resource Sharing (for Opera, IE).
            #$.support.cors = true
            o extends factory window.Backbone
            # Switch off waiting switch.
            @wait = false

    ###
    Chart Widget.
    @param {string} id Represents a widget identifier as represented in webconfig-model.xml
    @param {string} bagName List name to use with this Widget.
    @param {jQuery selector} el Where to render the Widget to.
    @param {Object} widgetOptions `{ "title": true/false, "description": true/false, "matchCb": function(id, type) {}, "resultsCb": function(pq) {}, "listCb": function(pq) {} }`
    ###
    chart: (opts...) =>
        if @wait then window.setTimeout((=> @chart(opts...)), 0)
        else
            # Load Google Visualization.
            google.load "visualization", "1.0",
                packages: [ "corechart" ]
                callback: => new o.ChartWidget(@service, @token, opts...)
    
    ###
    Enrichment Widget.
    @param {string} id Represents a widget identifier as represented in webconfig-model.xml
    @param {string} bagName List name to use with this Widget.
    @param {jQuery selector} el Where to render the Widget to.
    @param {Object} widgetOptions `{ "title": true/false, "description": true/false, "matchCb": function(id, type) {}, "resultsCb": function(pq) {}, "listCb": function(pq) {} }`
    ###
    enrichment: (opts...) =>
        # Wait to render the widget?
        if @wait
            window.setTimeout((=> @enrichment(opts...)), 0)
        else
            # Do we already have lists accessible to us?
            if @lists? then new o.EnrichmentWidget(@service, @token, @lists, opts...)
            else
                # First to get here slows the others.
                @wait = true
                # Fetch/cache lists this user has access to.
                $.ajax
                    'url': "#{@service}lists?token=#{@token}"
                    'dataType': 'jsonp'
                    'success': (data) =>
                        # Problems?
                        if data.statusCode isnt 200 and not data.lists?
                            $(opts[2]).html $ '<div/>',
                                'class': "alert alert-error"
                                'html':  "Problem fetching lists we have access to <a href='#{@service}lists'>#{@service}lists</a>"
                        else
                            # Save it and stop waiting.
                            @lists = data.lists ; @wait = false
                            # New instance of a widget.
                            new o.EnrichmentWidget(@service, @token, @lists, opts...)


    ###
    Table Widget.
    @param {string} id Represents a widget identifier as represented in webconfig-model.xml
    @param {string} bagName List name to use with this Widget.
    @param {jQuery selector} el Where to render the Widget to.
    @param {Object} widgetOptions `{ "title": true/false, "description": true/false, "matchCb": function(id, type) {}, "resultsCb": function(pq) {}, "listCb": function(pq) {} }`
    ###
    table: (opts...) =>
        if @wait then window.setTimeout((=> @table(opts...)), 0) else new o.TableWidget(@service, @token, opts...)

    ###
    All available List Widgets.
    @param {string} type Class of objects e.g. Gene, Protein.
    @param {string} bagName List name to use with this Widget.
    @param {jQuery selector} el Where to render the Widget to.
    @param {Object} widgetOptions `{ "title": true/false, "description": true/false, "matchCb": function(id, type) {}, "resultsCb": function(pq) {}, "listCb": function(pq) {} }`
    ###
    all: (type = "Gene", bagName, el, widgetOptions) =>
        if @wait then window.setTimeout((=> @all(type, bagName, el, widgetOptions)), 0)
        else
            $.ajax
                url:      "#{@service}widgets"
                dataType: "jsonp"
                
                success: (response) =>
                    # We have results.
                    if response.widgets
                        # For all that match our object type...
                        for widget in response.widgets when type in widget.targets
                            # Create target element for individual Widget (slugify just to make sure).
                            widgetEl = widget.name.replace(/[^-a-zA-Z0-9,&\s]+/ig, '').replace(/-/gi, "_").replace(/\s/gi, "-").toLowerCase()
                            $(el).append $('<div/>', id: widgetEl, class: "widget span6")
                            
                            # What type is it?
                            switch widget.widgetType
                                when "chart"
                                    @chart(widget.name, bagName, "#{el} ##{widgetEl}", widgetOptions)
                                when "enrichment"
                                    @enrichment(widget.name, bagName, "#{el} ##{widgetEl}", widgetOptions)
                                when "table"
                                    @table(widget.name, bagName, "#{el} ##{widgetEl}", widgetOptions)
                
                error: (xhr, opts, err) => $(el).html $ '<div/>',
                    class: "alert alert-error"
                    html:  "#{xhr.statusText} for <a href='#{@service}widgets'>#{@service}widgets</a>"


# Do we have the InterMine API Loader?
if not window.intermine
    throw 'You need to include the InterMine API Loader first!'
else
    window.intermine.widgets = Widgets