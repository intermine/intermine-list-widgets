### Enrichment Widget gene length correction.###

class EnrichmentLengthCorrectionView extends Backbone.View

    help: """
        Depending on the type of experiment your data comes from, it is sometimes 
        necessary to normalize by gene length in order to get the correct p-values. 
        If your data comes from a genome-wide binding experiment such as ChIP-seq 
        or DamID, binding intervals are more likely to be associated with longer 
        genes than shorter ones, and you should therefore normalize by gene length. 
        This is not the case for experiments such as gene expression studies, where 
        gene length does not play a role in the likelihood that a particular set of 
        genes will be overrepresented in the list.
    """

    events:
        'click .correction a.correction': 'toggleCull'
        'click .correction a.which': 'seeWhich'
        'hover .correction label .badge': 'showHelp'
        'click .correction a.close': 'hideHelp'

    initialize: (o) ->
        @[k] = v for k, v of o

        if @gene_length_correction isnt null then @render()

    render: =>
        # The wrapper.
        $(@el).append @widget.template "enrichment.correction", @

        @

    showHelp: =>
        $(@el).find('.hjalp').html @widget.template "popover.help",
            "title": 'What does "Normalise by length" mean?'
            "text":  @help

    hideHelp: => $(@el).find('.hjalp').empty()

    toggleCull: (e) =>
        # Toggle the active status and text.
        (el = $(e.target)).toggleClass('active').text ->
            if el.hasClass('active') then 'Normalised' else 'Normalise'
        # Set in form options.
        @widget.widget.formOptions['gene_length_correction'] = el.hasClass('active')
        # Re-render the widget.
        @widget.widget.render()

    # Will throw an exception when PQ not valid.
    seeWhich: (e) =>
        # Parse JSON.
        pq = JSON.parse @pathQueryGeneLengthNull
        @cb pq
        # Stop it.
        e.preventDefault()