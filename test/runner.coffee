#!/usr/bin/env coffee
Browser    = require 'zombie'
cheerio    = require 'cheerio'
{ assert } = require 'chai'
async      = require 'async'

console.log 'Zombie running'

spec = require './spec.coffee'

browser = new Browser
    'debug': false

# So we do not have to keep passing it around.
$ = null

# Hands off error checking.
err = null
do checkErrors = ->
    unless err
        setTimeout checkErrors, 50
    else
        throw new Error err.message

# A log stack.
log = []
browser.window.console.log = -> log.push arguments

# Are we there yet?
rendered = 0
browser.window.addEventListener 'InterMine', (obj) ->
    switch obj.event
        # An error?
        when 'error'
            err = obj
        # Increase count.
        when 'rendered'
            rendered++

# Start the service.
async.waterfall [ (cb) ->
    { start } = require '../service.coffee'
    start (err, port) ->
        assert.ifError err
        cb null, port

# Open the page.
(port, cb) ->
    browser.visit "http://localhost:#{port}", (err) ->
        assert.ifError err
        cb null

# Check until widgets loaded.
, (cb) ->
    do isDone = ->
        if rendered isnt 3
            setTimeout isDone, 250
        else
            cb null

, (cb) ->
    # Cheerio when loaded brother.
    $ = cheerio.load browser.html()

    # Just check we are on the right page.
    assert.equal $('h2.title').text(), 'Example List Widgets', 'page title not matching'

    # Go through the widgets and do DOM checks.
    for root, widget of spec
        for selector, fns of widget.dom
            for fn, value of fns
                # It better exist.
                assert $(root + ' ' + selector)[0], "`#{root} #{selector}` does not exist in DOM"
                # Check the contents.
                assert.equal $(root + ' ' + selector)[fn](), value

    cb null

, (cb) ->
    fns = []

    # Click around checks.
    for root, widget of spec then do (root, widget) ->
        for selector, value of widget.click
            fns.push (cb) ->
                # It better exist.
                assert $(root + ' ' + selector)[0], "`#{root} #{selector}` does not exist in DOM"
                # Click on it!
                browser.clickLink root + ' ' + selector, ->
                    # What are we actually checking?
                    for where, what of value
                        switch where
                            # Console log?
                            when 'log'
                                assert.deepEqual what, log.pop()[0]

                    # We done.
                    cb null

    # Run fns in sync as we work with a dummy logging stack.
    async.waterfall fns, cb

], (err) ->
    process.exit(0)