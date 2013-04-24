### Parent for all Widgets, handling templating, validation and errors.###

class InterMineWidget

    # Inject wrapper inside the target `div` that we have control over.
    constructor: ->
        $(@el).html $ '<div/>',
            'class': "inner"
            'style': "height:572px;overflow:hidden;position:relative"
        
        @el = "#{@el} div.inner"

        # Init imjs.
        @_service = new intermine.Service
            'root': @service
            'token': @token

    # Where is eco?
    template: (name, context = {}) -> JST["#{name}.eco"]?(context)

    # Validate JSON object against the spec.
    validateType: (object, spec) =>
        fails = []
        for key, value of object
            r = new spec[key]?(value)
            if r and not r.is()
                fails.push @template "invalidjsonkey",
                    key:      key
                    actual:   r.is()
                    expected: new String(r)
        
        if fails.length then @error fails, "JSONResponse"

    # The possible errors we handle.
    error: (opts={'title': 'Error', 'text': 'Generic error'}, type) =>
        # Add the name of the widget.
        opts.name = @name or @id
        
        # Which?
        switch type
            when "AJAXTransport"
                opts.title = "AJAX Request Failed"
            when "JSONResponse"
                opts.title = "Invalid JSON Response"
                opts.text = "<ol>#{opts.join('')}</ol>"

        # Show.
        $(@el).html @template "error", opts

        # Throw an error so we do not process further.
        @fireEvent 'event': 'error', 'type': type, 'message': opts.title

    # Fire a custom event (so we can capture in headless browser).
    fireEvent: (obj) ->
        evt = document.createEvent 'Events'
        evt.initEvent 'InterMine', true, true
        ( evt[key] = value for key, value of obj )
        evt.source = 'ListWidgets'
        evt.widget =
            'id':  @id
            'bag': @bagName
            'el':  @el
            'service': @service
        
        window.dispatchEvent evt

    # Call the service and return results.
    queryRows: (query, cb) =>
        service = @_service

        # Create a query.
        async.waterfall [ (cb) ->
            service.query query, (q) ->
                cb null, q
        
        # Turn query into rows.
        , (q, cb) ->
            q.rows (response) ->
                cb null, response
        
        ], (err, response) ->
            # TODO: Handle errors in a nice way.

            cb response