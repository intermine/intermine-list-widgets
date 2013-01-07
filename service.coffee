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