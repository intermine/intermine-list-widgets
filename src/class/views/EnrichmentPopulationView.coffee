### Enrichment Widget background population selection box.###

class EnrichmentPopulationView extends Backbone.View

    events:
        "click a.change": "toggleAction"
        "click a.close":  "toggleAction"
        "keyup input":    "filterAction"
        "click table a":  "selectListAction"

    initialize: (o) ->
        @[k] = v for k, v of o

        @render()

    render: =>
        $(@el).append @widget.template "enrichment.population", @
        @renderLists @lists

        @

    # Background population lists.
    renderLists: (lists) =>
        $(@el).find('div.values').html @widget.template "enrichment.populationlist",
            'lists': lists
            'selected': @selected

    # Show the background population selection.
    toggleAction: =>
        $(@el).find('div.popover').toggle()

    filterAction: (e) =>
        # Delay any further processing by a few.
        if @timeout? then clearTimeout @timeout

        @timeout = setTimeout (=>
            # Fetch the query value.
            query = $(e.target).val()
            if query isnt @query
                # Do the actual filtering.
                @query = query
                # Regex.
                re = new RegExp "#{query}.*", 'i'
                # Filter and re-render.
                @renderLists ( l for l in @lists when l.name.match(re) )
        ), 500

    # Select background population list.
    selectListAction: (e) =>
        list = $(e.target).text()
        e.preventDefault()
        @toggleAction()
        @widget.selectBackgroundList list