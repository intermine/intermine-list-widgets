fs       = require 'fs' # I/O
npath    = require 'path' # does path exist?
cs       = require 'coffee-script' # take a guess
eco      = require 'eco' # templating
{ exec } = require 'child_process' # execute custom commands
uglify   = require 'uglify-js' # minify JS code
async    = require 'async' # control flow
wrench   = require 'wrench' # recursive file operations
winston  = require 'winston' # cli logging

winston.cli()


# --------------------------------------------


# Version of the library automatic from package.json.
VERSION = null
# Main input/output.
MAIN =
    INPUT: "src/widgets.coffee"
    OUTPUT: "public/js/intermine.widgets.js"

# Templates dir.
TEMPLATES = "src/templates"
# Utils dir.
UTILS = "src/utils"
# Classes dir.
CLASSES = "src/class"


# --------------------------------------------


# Compile widgets.coffee and .eco templates into one output. Do not use globals for JST.
task 'build', 'compile widgets library and templates together', (options) ->
    async.waterfall [ (cb) ->
        #@+VERSION
        fs.readFile './package.json', 'utf8', (err, file) ->
            if err then cb err
            else
                VERSION = (JSON.parse(file)).version
                winston.info "Compiling version #{VERSION}"
                cb null, [], []

    # Compile templates.
    , (JS, CS, cb) ->
        winston.debug 'Compiling templates'

        JS.push 'var JST = {};'

        # If there are no more jobs then continue.
        jobs = 0 ; canExit = false
        exit = -> if jobs is 0 and canExit then cb null, JS, CS

        # Keep calling back on newly discovered files
        # Assume it takes less time then reading a file and compressing it.
        wrench.readdirRecursive TEMPLATES, (err, files) ->
            if err then cb err
            else
                # Are we done?
                unless files
                    canExit = true
                    exit()
                else
                    # Stack async functions and add a new job.
                    jobs++ ; fns = []
                    for file in files then do (file) ->
                        # Only take eco files.
                        if file.match /\.eco$/
                            fns.push (_cb) ->
                                winston.data file
                                # Read in file.
                                fs.readFile TEMPLATES + '/' + file, 'utf8', (err, data) ->
                                    if err then cb err
                                    else
                                        # Precompile.
                                        js = eco.precompile data
                                        # Get the name to save under.
                                        name = file.split('/').pop()
                                        # Compress.
                                        JS.push (uglify.minify("JST['#{name}'] = #{js}", 'fromString': true)).code
                                        # This one is done.
                                        _cb null

                    # Run all of them in parallel.
                    async.parallel fns, (err) ->
                        if err then cb err
                        else
                            # One more thing done.
                            jobs--
                            # Exit?
                            exit()

    # Compile utils.
    , (JS, CS, cb) ->
        winston.debug 'Compiling utils'

        # If there are no more jobs then continue.
        jobs = 0 ; canExit = false
        exit = -> if jobs is 0 and canExit then cb null, JS, CS

        # Keep calling back on newly discovered files
        # Assume it takes less time then reading a file and compressing it.
        wrench.readdirRecursive UTILS, (err, files) ->
            if err then cb err
            else
                # Are we done?
                unless files
                    canExit = true
                    exit()
                else
                    # Stack async functions and add a new job.
                    jobs++ ; fns = []
                    for file in files then do (file) ->
                        # Only take coffee files.
                        if file.match /\.coffee$/
                            fns.push (_cb) ->
                                winston.data file
                                # Read in file.
                                fs.readFile UTILS + '/' + file, 'utf8', (err, data) ->
                                    if err then cb err
                                    else
                                        CS.push data
                                        # This one is done.
                                        _cb null

                    # Run all of them in parallel.
                    async.parallel fns, (err) ->
                        if err then cb err
                        else
                            # One more thing done.
                            jobs--
                            # Exit?
                            exit()

    # Compile the main classes (access through factory).
    , (JS, CS, cb) ->
        winston.debug 'Compiling main classes'

        classes = [ 'factory = (Backbone) ->\n' ] ; names = []

        # If there are no more jobs then continue.
        jobs = 0 ; canExit = false
        exit = ->
            if jobs is 0 and canExit
                # Create a closing return statement exposing all classes.
                classes.push ( "  '#{name}': #{name}" for name in names ).join(',\n')
                CS.push classes

                cb null, JS, CS

        # Keep calling back on newly discovered files
        # Assume it takes less time then reading a file and compressing it.
        wrench.readdirRecursive CLASSES, (err, files) ->
            if err then cb err
            else
                # Are we done?
                unless files
                    canExit = true
                    exit()
                else
                    # Stack async functions and add a new job.
                    jobs++ ; fns = []
                    for file in files then do (file) ->
                        # Only take coffee files.
                        if file.match /\.coffee$/
                            fns.push (_cb) ->
                                winston.data file
                                # Read in file.
                                fs.readFile CLASSES + '/' + file, 'utf8', (err, source) ->
                                    if err then cb err
                                    else
                                        # Insert spaces as we are inside the factory function.
                                        source = ( "  #{line}\n" for line in source.split('\n') ).join('')
                                        
                                        # `InterMineWidget.coffee` needs to go first...
                                        if file.match /InterMineWidget\.coffee$/
                                            classes.splice 1, 0, source
                                        else
                                            classes.push source
                                        
                                        # Get the class name (it better match).
                                        names.push file.split('/').pop().split('.')[0]

                                        # This one is done.
                                        _cb null

                    # Run all of them in parallel.
                    async.parallel fns, (err) ->
                        if err then cb err
                        else
                            # One more thing done.
                            jobs--
                            # Exit?
                            exit()

    # Compile the public interface.
    , (JS, CS, cb) ->
        winston.debug 'Compiling public interface'

        winston.data MAIN.INPUT
        fs.readFile MAIN.INPUT, 'utf8', (err, file) ->
            if err then cb err
            else
                # Inject the version.
                CS.push file.replace '#@+VERSION', "'#{VERSION}'"

                cb null, JS, CS

    # Write output.
    , (JS, CS, cb) ->
        winston.debug 'Writing output'

        flatten = (input) ->
            output = []
            # Traverse.
            for item in input
                if item instanceof Array
                    output = output.concat flatten(item)
                else
                    output.push item
            output

        indent = (input) -> ( "  #{row}" for row in input.split('\n') ).join('\n')

        # Flatten JS.
        JS = flatten JS

        # Compile CoffeeScript to JavaScript.
        JS.push cs.compile flatten(CS).join('\n'), 'bare': 'on'

        # Combine JavaScript together, wrap in a fn & join on newlines.
        code = indent flatten(JS).join('\n')
        output = "(function() {\n  var o = {};\n#{code}\n}).call(this);"

        # Create file if it does not exist.
        fs.open MAIN.OUTPUT, 'w', 0o0666, (err) ->
            if err then cb err
            else
                # Append to existing file.
                fs.writeFile MAIN.OUTPUT, output, (err) ->
                    if err then cb err
                    else cb null

    ], (err) ->
        if err then winston.error error
        else winston.info 'Done'