### View maintaining Table Widget.###

class TableView extends Backbone.View

    events:
        "click div.actions a.view":      "viewAction"
        "click div.actions a.export":    "exportAction"
        "click div.content input.check": "selectAllAction"

    initialize: (o) ->
        @[k] = v for k, v of o

        # New **Collection**.
        @collection = new TableResults()
        @collection.bind('change', @renderToolbar) # Re-render toolbar on change.

        @render()

    render: ->
        # Render the widget template.
        $(@el).html @template "table",
            "title":       if @options.title then @response.title else ""
            "description": if @options.description then @response.description else ""
            "notAnalysed": @response.notAnalysed
            "type": @response.type

        # Results?
        if @response.results.length > 0
            # Render the toolbar & table, we have results.
            @renderToolbar()
            @renderTable()
        else
            # Render no results
            $(@el).find("div.content").html $ @template "noresults",
                'text': "No \"#{@response.title}\" with your list."

        @widget.fireEvent { 'class': 'TableView', 'event': 'rendered' }

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
            $ @template "table.table", "columns": @response.columns.split(',')
        )

        # Table rows **Models** and a subsequent **Collection**.
        table = $(@el).find("div.content table")
        for i in [0...@response.results.length] then do (i) =>            
            # New **Model**.
            row = new TableRow @response.results[i], @widget
            @collection.add row

        # Render row **Views**.
        @renderTableBody table

        # How tall should the table be? Whole height - header - faux header.
        height = $(@el).height() - $(@el).find('div.header').height() - $(@el).find('div.content div.head').height()
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
            fragment.appendChild new TableRowView(
                "model":     row
                "template":  @template
                "response":  @response
                "matchCb":   @options.matchCb
                "resultsCb": @options.resultsCb
                "listCb":    @options.listCb
                "widget":    @widget
            ).el

        # Append the fragment to trigger the browser reflow.
        table.find('tbody').html fragment

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
        
        # Create a tab delimited string of the table as it is.
        result = [ @response.columns.replace(/,/g, "\t") ]
        for model in selected
            result.push model.get('descriptions').join("\t") + "\t" + model.get('matches')

        if result.length
            try
                new Exporter result.join("\n"), "#{@widget.bagName} #{@widget.id}.tsv"
            catch TypeError
                new PlainExporter $(e.target), result.join("\n")

    # Selecting table rows and clicking on **View** should create an TableMatches collection of all matches ids.
    viewAction: =>
        # Select all if none selected (@kkara #164).
        selected = @collection.selected()
        if !selected.length then selected = @collection.models

        # Get all the identifiers for selected rows.
        descriptions = [] ; rowIdentifiers = []
        for model in selected
            # Grab the first (only?) description.
            descriptions.push model.get('descriptions')[0] ; rowIdentifiers.push model.get 'identifier'

        if rowIdentifiers.length # Can be empty.
            # Remove any previous matches modal window.
            @popoverView?.remove()

            # Append a new modal window with matches.
            $(@el).find('div.actions').after (@popoverView = new TablePopoverView(
                "identifiers":    rowIdentifiers
                "description":    descriptions.join(', ')
                "template":       @template
                "matchCb":        @options.matchCb
                "resultsCb":      @options.resultsCb
                "listCb":         @options.listCb
                "pathQuery":      @response.pathQuery
                "pathConstraint": @response.pathConstraint
                "widget":         @widget
                "type":           @response.type
                "style":          'width:300px'
            )).el