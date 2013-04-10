### Enrichment Widget table row.###

class EnrichmentRowView extends Backbone.View

    tagName: "tr"

    events:
        "click td.check input":     "selectAction"
        "click td.matches a.count": "toggleMatchesAction"

    initialize: (o) ->
        @[k] = v for k, v of o

        @model.bind('change', @render)

        @render()

    render: =>
        $(@el).html @template "enrichment.row", "row": @model.toJSON()
        @

    # Toggle the `selected` attr of this row object.
    selectAction: =>
        @model.toggleSelected()

        # Have we got popover view to inject?
        if @popoverView?
            $(@el).find('td.matches a.count').after @popoverView.el
            # Re-delegate all events.
            @popoverView.delegateEvents()

    # Show matches.
    toggleMatchesAction: (e) =>
        if not @popoverView?
            $(@el).find('td.matches a.count').after (@popoverView = new EnrichmentPopoverView(
                "matches":     @model.get "matches"
                "identifiers": [ @model.get "identifier" ]
                "description": @model.get "description"
                "template":    @template
                "matchCb":     @callbacks.matchCb
                "resultsCb":   @callbacks.resultsCb
                "listCb":      @callbacks.listCb
                "response":    @response
                "widget":      @widget
                "size":        $(e.target).text() # get the number of matches we clicked on
            )).el
        else @popoverView.toggle()
