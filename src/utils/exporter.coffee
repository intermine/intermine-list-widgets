### Create file download with custom content.###

# Generate and download a file from a string.
class Exporter

    mime:    'text/plain'
    charset: 'utf-8'

    ###
    Use `BlobBuilder` and `URL` to force download dynamic string as a file.
    @param {object} a jQuery element
    @param {string} data string to download
    @param {string} filename to save under
    ###
    constructor: (data, filename = 'widget.tsv') ->
        blob = new Blob [ data ], 'type': "#{@mime};charset=#{@charset}"
        saveAs blob, filename

# For old browsers.
class PlainExporter

    ###
    Create a new window with a formatted content.
    @param {object} a jQuery element
    @param {string} data string to download
    ###
    constructor: (a, data) ->
        w = window.open()

        # Are popups blocked? Why? ;)
        if not w? or typeof w is "undefined"
            a.after @msg = $ '<span/>',
                'style': 'margin-left:5px'
                'class': 'label label-inverse'
                'text':  'Please enable popups'
        else
            w.document.open()
            w.document.write "<pre>#{data}</pre>"
            w.document.close()

        # Clean up popup message if present.
        destroy = => @msg?.fadeOut()
        setTimeout destroy, 5000