### View maintaining Chart Widget.###

class ChartView extends Backbone.View

    # Google Visualization chart options.
    chartOptions:
        fontName: "Sans-Serif"
        fontSize: 11
        colors:   [ "#2F72FF", "#9FC0FF" ]
        legend:
            position: "top"
        chartArea:
            top:    30
            bottom: 80
            left:   50
        hAxis:
            titleTextStyle:
                fontName: "Sans-Serif"
        vAxis:
            titleTextStyle:
                fontName: "Sans-Serif"

    # ColorBrewer Blues.
    brewer:
        '3': ["rgb(189,215,231)", "rgb(107,174,214)", "rgb(33,113,181)"]
        '4': ["rgb(189,215,231)", "rgb(107,174,214)", "rgb(49,130,189)", "rgb(8,81,156)"]
        '5': ["rgb(198,219,239)", "rgb(158,202,225)", "rgb(107,174,214)", "rgb(49,130,189)", "rgb(8,81,156)"]
        '6': ["rgb(198,219,239)", "rgb(158,202,225)", "rgb(107,174,214)", "rgb(66,146,198)", "rgb(33,113,181)", "rgb(8,69,148)"]
        '7': ["rgb(222,235,247)", "rgb(198,219,239)", "rgb(158,202,225)", "rgb(107,174,214)", "rgb(66,146,198)", "rgb(33,113,181)", "rgb(8,69,148)"]
        '8': ["rgb(222,235,247)", "rgb(198,219,239)", "rgb(158,202,225)", "rgb(107,174,214)", "rgb(66,146,198)", "rgb(33,113,181)", "rgb(8,81,156)", "rgb(8,48,107)"]

    # Multiselect mode?
    multiselect: false

    events:
        "change div.form select":       "formAction"
        "click div.actions a.view-all": "viewAllAction"

    initialize: (o) ->
        @[k] = v for k, v of o

        # Keyup events for the whole page.
        $(document).on 'keyup keydown', @keypressAction

        @render()

    render: ->
        # Render the widget template.
        $(@el).html @template "chart",
            "title":       if @options.title then @response.title else ""
            "description": if @options.description then @response.description else ""
            "notAnalysed": @response.notAnalysed
            "type": @response.type

        # Extra attributes (DataSets etc.)?
        if @response.filterLabel?
            $(@el).find('div.form form').append @template "extra",
                "label":    @response.filterLabel
                "possible": @response.filters.split(',') # Is a String unfortunately.
                "selected": @response.filterSelectedValue

        # Are the results empty?
        if @response.results.length > 1
            # Create the chart.
            if @response.chartType of google.visualization # If the type exists...

                # Add actions toolbar.
                @renderToolbar()

                # Set the width/height of the drawing area.
                width = $(@el).width() ; height = $(@el).height() - $(@el).find('div.header').height()
                @chartOptions.width = width
                @chartOptions.chartArea.width = width - @chartOptions.chartArea.left
                @chartOptions.height = height
                @chartOptions.chartArea.height = height - @chartOptions.chartArea.top - @chartOptions.chartArea.bottom

                # Set the legend on axes.
                @chartOptions.hAxis =
                    'title': if @response.chartType is 'BarChart' then @response.rangeLabel else @response.domainLabel
                @chartOptions.vAxis =
                    'title': if @response.chartType is 'BarChart' then @response.domainLabel else @response.rangeLabel

                chart = new google.visualization[@response.chartType]($(@el).find("div.content")[0])

                # Lose focus on the `<iframe>` you stupid stupid Google Viz.
                google.visualization.events.addListener chart, 'click', =>
                    # Create fake input element and give it focus immediately destroying it.
                    $(@el).find('.content').prepend input = $ '<input/>',
                        'class': 'focus'
                        'type':  'text'
                    input.focus().remove()

                # Add event listener on click the chart bar.
                if @response.pathQuery? then google.visualization.events.addListener chart, "select", => @viewBarAction chart

                # Is this a single series or double series chart?
                if @response.results[0].length is 1
                    # Need to prefix a domain label to make it into 2D array throughout.
                    @response.results[0] = [ @response.domainLabel, @response.results[0][0] ]

                # Duplicate chart options.
                options = JSON.parse JSON.stringify @chartOptions

                # If we have a PieChart with 3+ things to display use ColorBrewer colors.
                if @response.chartType is 'PieChart' and (ln = @response.results.length - 1) >= 3
                    if ln > 8 then ln = 8 # we only have 8 colors max (do not use fairest).
                    options.colors = @brewer[ln].reverse() # start with dark colors

                # Draw.
                chart.draw(google.visualization.arrayToDataTable(@response.results, false), options)

            else
                # Undefined Google Visualization chart type.
                @error 'title': @response.chartType, 'text': "This chart type does not exist in Google Visualization API"

        else
            # Render no results.
            $(@el).find("div.content").html $ @template "noresults",
                'text': "No \"#{@response.title}\" with your list."

        @widget.fireEvent { 'class': 'ChartView', 'event': 'rendered' }

        @

    renderToolbar: =>
        $(@el).find("div.actions").html(
            $ @template "chart.actions"
        )

    # Translate view series into PathQuery series (Expressed/Not Expressed into true/false).
    translate: (response, series) ->
        # Chromosome Distribution widget fails on this step not having `seriesValues`.
        if response.seriesValues?
            response.seriesValues.split(',')[response.seriesLabels.split(',').indexOf(series)]

    # Monitor key-presses of command keys to do multiselect.
    keypressAction: (e) =>
        if e.type is 'keydown'
            if e.keyCode >= 16 and e.keyCode <= 18
                # Set multiselect mode.
                @multiselect = true
        else
            if e.keyCode >= 16 and e.keyCode <= 18
                # Switch off multiselect.
                @multiselect = false
                # Show the collated bars.
                if @selection? and @selection.length isnt 0
                    @viewBarsAction @selection
                    @selection = null

    # Listener for bar onclick.
    viewBarAction: (chart) =>
        # Remove any previous popovers.
        if @barView? then @barView.close()

        # Get the selection.
        selection = chart.getSelection()[0]

        # Multiselect mode?
        if @multiselect
            @selection ?= []
            @selection.push selection
        else
            # We are selecting things.
            if selection
                # Determine which bar we are in.
                description = '' ; resultsPq = @response.pathQuery ; quickPq = @response.simplePathQuery
                if selection.row?
                    row = @response.results[selection.row + 1][0]
                    description += row

                    # Replace `%category` in PathQueries.
                    resultsPq = resultsPq.replace "%category", row ; quickPq = quickPq.replace "%category", row

                    # Replace `%series` in PathQuery.
                    if selection.column?
                        # Issue #159.
                        return false if @response.seriesPath is 'ActualExpectedCriteria' and selection.column is 2

                        # Parse.
                        column = @response.results[0][selection.column]
                        description += ' ' + column
                        resultsPq = resultsPq.replace("%series", @translate @response, column)
                        quickPq =   resultsPq.replace("%series", @translate @response, column)
                else
                    # We have clicked legend series.
                    if selection.column?
                        return @viewSeriesAction resultsPq.replace("%series", @translate @response, @response.results[0][selection.column])

                # Turn into JSON object?
                resultsPq = JSON.parse resultsPq ; quickPq = JSON.parse quickPq

                # We may have deselected a bar.
                if description
                    # Create `View`
                    $(@el).find('div.content').append (@barView = new ChartPopoverView(
                        "description": description
                        "template":    @template
                        "resultsPq":   resultsPq
                        "resultsCb":   @options.resultsCb
                        "listCb":      @options.listCb
                        "matchCb":     @options.matchCb
                        "quickPq":     quickPq
                        "widget":      @widget
                        "type":        @response.type
                    )).el

    # Command select multiple bars action.
    viewBarsAction: (selections) =>
        # Parse full PathQuery.
        pq = JSON.parse @response.pathQuery
        
        # Split the constraints in the pq.
        for i, field of pq.where
            switch field.value
                when '%category' then category = field
                when '%series' then series = field
                else
                    field.code = 'A'
                    bag = field

        # Remove the constraints from pq.
        pq.where = [ bag, category, series ] ; pq.constraintLogic = ''

        # Or logic for all the constraints we are merging.
        orLogic = [ ]

        # Char code for char to use in logic.
        code = 66 # 'B'

        constraints = [ bag ]
        # Have we used this constraint before?
        getConstraint = (newConstraint) ->
            for constraint in constraints
                if constraint.path is newConstraint.path and constraint.value is newConstraint.value
                    return constraint.code
        
        # Traverse the selection making an array of constraints.
        for selection in selections
            if selection? and category?
                # Category.
                constraint = $.extend true, {}, category,
                    'value': @response.results[selection.row + 1][0]

                a = getConstraint(constraint)
                if not a?
                    # New constraint.
                    constraint.code = a = String.fromCharCode(code++).toUpperCase()                    
                    constraints.push constraint

                # Series.
                if selection.column? and series?
                    constraint = $.extend true, {}, series,
                        'value': @translate @response, @response.results[0][selection.column]
                    
                    b = getConstraint(constraint)
                    if not b?
                        # New constraint.
                        constraint.code = b = String.fromCharCode(code++).toUpperCase()
                        constraints.push constraint

                    orLogic.push '(' + [a, b].join(' AND ') + ')'
                else
                    orLogic.push a

        # At least some error check...
        if code > 90 then throw 'Too many constraints'

        # Update the pq.
        pq.constraintLogic = [ 'A', '(' + orLogic.join(' OR ') + ')' ].join(' AND ')
        pq.where = constraints

        # In fact, we may only have one constraint... the bag.
        if code > 66 then @options.resultsCb pq

    # View both series.
    viewAllAction: =>
        # Parse full PathQuery.
        pq = JSON.parse @response.pathQuery

        # Remove both '%category%' and '%series%'.
        for rem in [ '%category', '%series' ]
            for i, field of pq.where
                if field?.value is rem
                    pq.where.splice i, 1
                    break

        @options.resultsCb pq

    # Clicking on legend we call `resultsCb` constraining on '%series%'
    viewSeriesAction: (pathQuery) =>
        # Parse full PathQuery.
        pq = JSON.parse pathQuery

        # Remove '%category%' only.
        for i, field of pq.where
            if field?.value is '%category'
                pq.where.splice i, 1
                break

        @options.resultsCb pq

    # On form select option change, set the new options and re-render.
    formAction: (e) =>
        @widget.formOptions[$(e.target).attr("name")] = $(e.target[e.target.selectedIndex]).attr("value")
        @widget.render()