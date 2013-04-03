#!/usr/bin/env coffee
flatiron = require 'flatiron'
connect  = require 'connect'
urlib    = require 'url'
fs       = require 'fs'

exports.start = (cb) ->
    # Config filters.
    app = flatiron.app
    app.use flatiron.plugins.http,
        'before': [
            connect.favicon()
            connect.static __dirname + '/public'
        ]

    # Start the server app.
    app.start process.env.PORT, (err) ->
        if cb and typeof(cb) is 'function'
            return cb err if err
            cb null, app.server.address().port
        else
            throw err if err
            app.log.info "Listening on port #{app.server.address().port}".green