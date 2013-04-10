### Table Widget table row matches box.###

class TablePopoverView extends Backbone.View

    # How many characters can we display in the description?
    descriptionLimit: 50

    # How many objects do we show before ending with an ellipsis?
    valuesLimit: 5

    events:
        'click a.match':   'matchAction'
        'click a.results': 'resultsAction'
        'click a.list':    'listAction'
        'click a.close':   'toggle'

    initialize: (o) ->
        @[k] = v for k, v of o

        @render()

    render: =>
        $(@el).css 'position':'relative'
        $(@el).html @template 'popover',
            'description':      @description
            'descriptionLimit': @descriptionLimit
            'style':            @style or "width:300px;margin-left:-300px"

        # Modify JSON to constrain on these matches.
        @pathQuery = JSON.parse @pathQuery
        # Add the ONE OF constraint.
        @pathQuery.where.push
            'path':   @pathConstraint
            'op':     'ONE OF'
            'values': @identifiers

        # Grab the data.
        @widget.queryRows @pathQuery, @renderValues

        @

    # Render the values from imjs request.
    renderValues: (response) =>
        values = []
        for object in response
            values.push do (object) ->
                for column in object
                    return column if column and column.length > 0

        $(@el).find('div.values').html @template 'popover.values',
            'values':      values
            'type':        @type
            'valuesLimit': @valuesLimit
            'size':        @size # size is the number of matches count we clicked on

        # Now that the size has changed, adjust the popover.
        @adjustPopover()

    # Onclick the individual match, execute the callback.
    matchAction: (e) =>
        @matchCb $(e.target).text(), @type
        e.preventDefault()

    # View results action callback.
    resultsAction: => @resultsCb @pathQuery

    # Create a list action.
    listAction: => @listCb @pathQuery

    # Adjust popover position so that it is not cutoff if too close to the edge.
    adjustPopover: =>
        window.setTimeout (=>
            table =         $(@el).closest('div.wrapper') # wrapper for table height
            popover =       $(@el).find('.popover') # popover
            parent =        popover.closest('td.matches') # table cell
            return unless parent.length # not in a table context
            widget =        parent.closest('div.inner')
            header =        widget.find('div.header') # header before content
            head =          widget.find('div.content div.head') # table head

            # Adjust the negative position from top to see the popover.
            diff =          ((parent.position().top - header.height() + head.height()) + popover.outerHeight()) - table.height()
            if diff > 0 then popover.css 'top', -diff
        ), 0

    # Toggle me on/off.
    toggle: =>
        $(@el).toggle()
        @adjustPopover()
