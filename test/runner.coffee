#!/usr/bin/env coffee
Browser    = require 'zombie'
cheerio    = require 'cheerio'
{ assert } = require 'chai'
async      = require 'async'

spec = require './spec.coffee'

# Trim whitespace.
String::trim = -> @.replace(/^\s+|\s+$/g, '').replace(/\s{2,}/g, ' ')

# Sync DOM validation be it after an event or outright.
domValidator = (root, obj) ->
    for selector, fns of obj
        for fn, value of fns
            # It better exist.
            assert $(root + ' ' + selector)[0], "`#{root} #{selector}` does not exist in DOM"
            
            # What kind of a function is it?
            if attr = fn.match /attr\((.*)\)/
                # Attribute check.
                assert $(root + ' ' + selector).attr(attr[1]), value, "`#{selector}` fail"
            else
                # Standard contents check.
                assert fn in [ 'text', 'html', 'toArray' ], "unrecognized function `#{fn}`"

                # Are we matching against an array?
                if value instanceof Array
                    # Apply the function after making into an array first.
                    arr = ( ($(el)[fn]()).trim() for i, el of $(root + ' ' + selector).toArray() )
                    # Do we match.
                    assert.deepEqual arr, value, "`#{selector}` fail"
                else
                    # Straight up.
                    assert.equal ($(root + ' ' + selector)[fn]()).trim(), value, "`#{selector}` fail"

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
    $ = cheerio.load browser.html(),
        'ignoreWhitespace': true
        'lowerCaseTags': true

    # Just check we are on the right page.
    assert.equal $('h2.title').text(), 'Example List Widgets', 'page title not matching'

    # Go through the widgets and do DOM checks.
    for root, widget of spec
        domValidator root, widget.dom
    
    cb null

], (err) ->
    process.exit(0)