#!/usr/bin/env coffee

flatiron = require 'flatiron'
connect  = require 'connect'
urlib    = require 'url'
fs       = require 'fs'

# Config filters.
app = flatiron.app
app.use flatiron.plugins.http,
    'before': [
        connect.favicon()
        connect.static __dirname + '/public'
    ]

# Start the server app.
app.start process.env.PORT, (err) ->
    throw err if err
    app.log.info "Listening on port #{app.server.address().port}".green

# Widgets listing.
app.router.path '/widgets', ->
    @get ->
        fs.readFile './public/json/widgets.json', 'utf-8', (err, data) =>
            @res.writeHead 200, "content-type": "application/javascript"
            @res.write "#{@req.query.callback}(#{data});"
            @res.end()

# Lists we have access to.
app.router.path '/lists', ->
    @get ->
        fs.readFile './public/json/lists.json', 'utf-8', (err, data) =>
            @res.writeHead 200, "content-type": "application/javascript"
            @res.write "#{@req.query.callback}(#{data});"
            @res.end()

# Enrichment widgets.
app.router.path '/list/enrichment', ->
    @get ->
        fs.readFile "./public/json/enrichment/#{@req.query.widget}.json", 'utf-8', (err, data) =>
            @res.writeHead 200, "content-type": "application/javascript"
            @res.write "#{@req.query.callback}(#{data});"
            @res.end()