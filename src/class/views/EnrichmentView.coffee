### View maintaining Enrichment Widget.###

class EnrichmentView extends Backbone.View

    events:
        "click div.actions a.view":      "viewAction"
        "click div.actions a.export":    "exportAction"
        "change div.form select":        "formAction"
        "click div.content input.check": "selectAllAction"

    initialize: (o) ->
        @[k] = v for k, v of o

        # New **Collection**.
        @collection = new EnrichmentResults()
        @collection.bind('change', @renderToolbar) # Re-render toolbar on change.

        @render()

    render: ->
        # Render the widget template.
        $(@el).html @template "enrichment",
            "title":       if @options.title then @response.title else ""
            "description": if @options.description then @response.description else ""
            "notAnalysed": @response.notAnalysed
            "type": @response.type

        # Form options.
        $(@el).find("div.form").html @template "enrichment.form",
            "options":          @form.options
            "pValues":          @form.pValues
            "errorCorrections": @form.errorCorrections

        # Extra attributes (DataSets etc.)?
        if @response.filterLabel?
            $(@el).find('div.form form').append @template "extra",
                "label":    @response.filterLabel
                "possible": @response.filters.split(',') # Is a String unfortunately.
                "selected": @response.filterSelectedValue

        # Background population lists.
        new EnrichmentPopulationView
            'el': $(@el).find('div.form form')
            'lists': @lists
            'current': @response.current_population
            'loggedIn': @response.is_logged
            'widget': @

        # Do we have extra attributes?
        if @response.extraAttribute
            extraAttribute = JSON.parse @response.extraAttribute

            # Enrichment gene length correction.
            if extraAttribute.gene_length
                opts = merge extraAttribute.gene_length,
                    'el': $(@el).find('div.form form')
                    'widget': @
                    'cb': @options.resultsCb                    

                new EnrichmentLengthCorrectionView opts

        # Custom bg population CSS.
        if @response.current_list?
            $(@el).addClass 'customBackgroundPopulation'
        else
            $(@el).removeClass 'customBackgroundPopulation'

        # Results?
        if @response.results.length > 0 and !@response.message?
            # Render the actions toolbar, we have results.
            @renderToolbar()

            @renderTable()
        else
            # Render no results
            $(@el).find("div.content").html $ @template "noresults",
                'text': @response.message or 'No enrichment found.'

        @widget.fireEvent { 'class': 'EnrichmentView', 'event': 'rendered' }

        @

    # Render the actions toolbar based on how many collection model rows are selected.
    renderToolbar: =>
        $(@el).find("div.actions").html(
            $ @template "actions"
        )

    # Render the table of results using Document Fragment to prevent browser reflows.
    renderTable: =>
        # Render the table.
        $(@el).find("div.content").html(
            $ @template "enrichment.table", "label": @response.label
        )

        # Table rows **Models** and a subsequent **Collection**.
        table = $(@el).find("div.content table")
        for i in [0...@response.results.length] then do (i) =>
            # Form the data.
            data = @response.results[i]
            # External link through simple append.
            if @response.externalLink then data.externalLink = @response.externalLink + data.identifier
            
            # New **Model**.
            row = new EnrichmentRow data, @widget
            @collection.add row

        # Render row **Views**.
        @renderTableBody table

        # How tall should the table be? Whole height - header - faux header.
        height = $(@el).height() - $(@el).find('div.header').height() - $(@el).find('div.content table thead').height()
        $(@el).find("div.content div.wrapper").css 'height', "#{height}px"

        # Determine the width of the faux head element.
        $(@el).find("div.content div.head").css "width", $(@el).find("div.content table").width() + "px"

        # Fix the `div.head` elements width.
        table.find('thead th').each (i, th) =>
            $(@el).find("div.content div.head div:eq(#{i})").width $(th).width()

        # Fix the `table` margin to hide gap after invisible `thead` element.
        table.css 'margin-top': '-' + table.find('thead').height() + 'px'

    # Render `<tbody>` from a @collection (use to achieve single re-flow of row Views).
    renderTableBody: (table) =>
        # Create a Document Fragment for the content that follows.
        fragment = document.createDocumentFragment()

        # Table rows.
        for row in @collection.models
            # Render.
            fragment.appendChild new EnrichmentRowView(
                "model":     row
                "template":  @template
                "type":      @response.type
                "callbacks": { "matchCb": @options.matchCb, "resultsCb": @options.resultsCb, "listCb": @options.listCb }
                "response":  @response
                "widget":    @widget
            ).el

        # Append the fragment to trigger the browser reflow.
        table.find('tbody').html fragment

    # On form select option change, set the new options and re-render.
    formAction: (e) =>
        @widget.formOptions[$(e.target).attr("name")] = $(e.target[e.target.selectedIndex]).attr("value")
        @widget.render()

    # (De-)select all.
    selectAllAction: =>
        @collection.toggleSelected()
        @renderToolbar()
        @renderTableBody $(@el).find("div.content table")

    # Export selected rows into a file.
    exportAction: (e) =>
        # Select all if none selected (@kkara #164).
        selected = @collection.selected()
        if !selected.length then selected = @collection.models

        # Get column identifiers to constrain on.
        rowIdentifiers = []
        for model in selected
            rowIdentifiers.push model.get 'identifier'

        # PathQuery for matches values.
        pq = JSON.parse @response['pathQueryForMatches']
        pq.where.push
            "path":   @response.pathConstraint
            "op":     "ONE OF"
            "values": rowIdentifiers

        # Get the actual data.
        @widget.queryRows pq, (response) =>
            # Assume the first column is the table column, while second is the matches object identifier (Gene).
            # Form 'publication -> genes' object.
            dict = {}
            for object in response
                if not dict[object[0]]? then dict[object[0]] = []
                dict[object[0]].push object[1]

            # Create a tab delimited string.
            result = []
            for model in selected
                result.push [ model.get('description'), model.get('p-value') ].join("\t") + "\t" + dict[model.get('identifier')].join(',')

            if result.length
                try
                    new Exporter result.join("\n"), "#{@widget.bagName} #{@widget.id}.tsv"
                catch TypeError
                    new PlainExporter $(e.target), result.join("\n")

    # Selecting table rows and clicking on **View** should create an EnrichmentMatches collection of all matches ids.
    viewAction: =>
        # Select all if none selected (@kkara #164).
        selected = @collection.selected()
        if !selected.length then selected = @collection.models

        # Get all the matches in selected rows.
        descriptions = [] ; rowIdentifiers = []
        for model in selected
            descriptions.push model.get 'description' ; rowIdentifiers.push model.get 'identifier'

        if rowIdentifiers.length # Can be empty.
            # Remove any previous matches modal window.
            @popoverView?.remove()

            # Append a new modal window with matches.
            $(@el).find('div.actions').after (@popoverView = new EnrichmentPopoverView(
                "identifiers": rowIdentifiers
                "description": descriptions.join(', ')
                "template":    @template
                "style":       "width:300px"
                "matchCb":     @options.matchCb
                "resultsCb":   @options.resultsCb
                "listCb":      @options.listCb
                "response":    @response
                "widget":      @widget
            )).el

    # Select background population list.
    selectBackgroundList: (list, save=false) =>
        # Pass in `null` to go default. Could be better than string match as we could have a list called Default.
        if list is 'Default' then list = ''

        # Change the list.
        @widget.formOptions['current_population'] = list

        # Remember this list as a background population.
        @widget.formOptions['remember_population'] = save
        
        # Re-render.
        @widget.render()