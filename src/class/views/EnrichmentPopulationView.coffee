### Enrichment Widget background population selection box.###

class EnrichmentPopulationView extends Backbone.View

    events:
        "click .background a.change":     "toggleAction"
        "click .background a.close":      "toggleAction"
        "keyup .background input.filter": "filterAction"
        "click .background table a":      "selectListAction"

    initialize: (o) ->
        @[k] = v for k, v of o

        @render()

    render: =>
        # The wrapper.
        $(@el).append @widget.template "enrichment.population",
            'current': if @current? then @current else 'Default'
            'loggedIn': @loggedIn

        # The lists.
        @renderLists @lists

        @

    # Background population lists.
    renderLists: (lists) =>
        $(@el).find('div.values').html @widget.template "enrichment.populationlist",
            'lists': lists
            'current': @current

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
        # Who are you?
        list = $(e.target).text()
        
        # No linking on our turf.
        e.preventDefault()

        # Hide us.
        @toggleAction()

        # Do the bidding.
        @widget.selectBackgroundList list, $(@el).find('input.save:checked').length is 1