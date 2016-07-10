{union, join} = require \prelude-ls
require! 'gulp-livescript': lsc
require! <[ gulp glob path]>
require! 'vinyl-source-stream': source
require! 'vinyl-buffer': buffer
require! 'vinyl-transform': transform
require! 'gulp-plumber': plumber
require! 'gulp-watch': watch
require! 'gulp-jade': jade
require! 'node-notifier': notifier
require! 'gulp-concat': cat
require! 'browserify-livescript'
require! 'browserify': browserify
require! 'gulp-uglify': uglify
require! 'gulp-sourcemaps': sourcemaps
require! './src/lib/aea': {sleep}
require! 'fs'

# TODO: combine = require('stream-combiner')

# Build Settings
notification-enabled = yes

# Project Folder Structure
vendor-folder = './vendor'
server-src = "./src/server"
build-folder = "./build"

client-public = "#{build-folder}/public"
client-src = './src/client'
client-tmp = "#{build-folder}/__client-tmp"

lib-src = "./src/lib"
lib-tmp = "#{build-folder}/__lib-tmp"

components-src = "#{client-src}/components"
components-tmp = "#{client-tmp}/components"

on-error = (source, err) ->
    msg = "GULP ERROR: #{source} :: #{err?.to-string!}"
    notifier.notify {title: "GULP.#{source}", message: msg} if notification-enabled
    console.log msg


list-rel-files = (base, main, file-list) ->
        main = "#{base}/components.jade"
        ["./#{f}" - "#{base}/" for f in file-list when f isnt main]


# Organize Tasks
gulp.task \default, ->
    console.log "task lsc is running.."
    do function run-all
        gulp.start <[ js info-browserify html vendor vendor-css assets jade ]>

    # watch for component changes
    watch ["#{client-src}/components/**/*.*", "!#{client-src}/components/*.jade", "!#{client-src}/components/*.ls"] , (event) ->
        gulp.start <[ jade info-browserify ]>

    # watch for jade changes
    watch ["#{client-src}/**/*.jade"], ->
        gulp.start \jade
        
    watch "#{client-src}/pages/*.*", (event) ->
        run-all!
    watch "#{lib-src}/**/*.*", (event) ->
        run-all!
    watch "#{vendor-folder}/**", (event) ->
        gulp.start <[ vendor vendor-css ]>

# Copy js and html files as is
gulp.task \js, ->
    gulp.src "#{client-src}/**/*.js", {base: client-src}
        .pipe gulp.dest client-tmp

gulp.task \html, ->
    gulp.src "#{client-src}/**/*.html", {base: client-src}
        .pipe gulp.dest client-tmp


# Compile client LiveScript files into temp folder
gulp.task \lsc-client <[ generate-components-module ]> ->
    gulp.src "#{client-src}/**/*.ls", {base: client-src}
        .pipe lsc!
        .on \error, (err) ->
            on-error \lsc-lib, err
            @emit \end
        .pipe gulp.dest client-tmp

gulp.task \generate-components-module ->
    glob "#{components-src}/*", (err, filepath) ->
        base = components-src
        main = "#{base}/components.ls"
        components = ["#{f}" - "#{base}/" for f in filepath when f isnt main]

        # TODO: get only directories
        components = [.. for components when ..split '.' .length < 2]

        # delete the main file
        fs.write-file-sync main, '# Do not edit this file manually! \n'
        fs.append-file-sync main, join "" ["require! './#{..}'\n" for components]
        fs.append-file-sync main, "module.exports = { #{join ', ', components} }\n"



# Compile library modules into library temp folder
gulp.task \lsc-lib, ->
    gulp.src "#{lib-src}/**/*.ls", {base: lib-src}
        .pipe lsc!
        .on \error, (err) ->
            on-error \lsc-lib, err
            @emit \end
        .pipe gulp.dest lib-tmp


# Browserify pages/* into public folder
gulp.task \info-browserify <[ browserify ]> ->
    console.log "Browserifying finished!"

gulp.task \browserify <[ lsc-client lsc-lib js]> ->
    glob "#{client-tmp}/pages/**/*.js", (err, filepath) ->
        for f in filepath
            filename = f.split '/' .slice -1
            base-folder = "#{f}" - "#{client-tmp}/" - "/#{filename}"
            browserify f, {paths: [components-tmp, lib-tmp]}
                .bundle!
                .on \error, (err) ->
                    on-error \browserify, err
                    @emit \end
                .pipe source "#{filename}"
                .pipe buffer!
                ## Source Maps are working (needs more testing)
                #.pipe sourcemaps.init {+load-maps}
                #.pipe uglify!
                #.pipe sourcemaps.write!
                .pipe gulp.dest "#{client-public}/#{base-folder}"


# Concatenate vendor javascript files into public/js/vendor.js
gulp.task \vendor, ->
    order =
        './ractive.js'
        './jquery-1.12.0.min.js'
        # and the rest...

    glob "#{vendor-folder}/**/*.js", (err, files) ->
        ordered-list = union order, (list-rel-files vendor-folder, '', files)
        console.log "ordered list is: ", ordered-list
        gulp.src ["#{vendor-folder}/#{..}" for ordered-list]
            .pipe cat "vendor.js"
            .pipe gulp.dest "#{client-public}/js"

# Concatenate vendor css files into public/css/vendor.css
gulp.task \vendor-css, ->
    glob "#{vendor-folder}/**/*.css", (err, files) ->
        gulp.src files
            .pipe cat "vendor.css"
            .pipe gulp.dest "#{client-public}/css"

# Copy assets into the public directory as is
gulp.task \assets, ->
    gulp.src "#{client-src}/assets/**/*", {base: "#{client-src}/assets"}
        .pipe gulp.dest client-public

# Compile Jade files in client-src to the client-tmp folder
gulp.task \jade <[ jade-components ]> ->
    gulp.src "#{client-src}/pages/*.jade", {base: client-src}
        .pipe jade {pretty: yes}
        .on \error, (err) ->
            on-error \jade, err
            @emit \end
        .pipe gulp.dest client-public


gulp.task \jade-components ->
    # create a file which includes all jade file includes in it

    glob "#{components-src}/**/*.jade", {base: components-src}, (err, filepath) ->
        base = components-src
        main = "#{base}/components.jade"
        components = ["./#{f}" - "#{base}/" for f in filepath when f isnt main]

        # delete the main file
        fs.write-file-sync main, '// Do not edit this file manually! \n'

        i = 0
        <- :lo(op) ->
            console.log "Adding component: ",components[i]
            fs.append-file-sync main, "include #{components[i]}\n"
            if ++i < components.length
                lo(op)
