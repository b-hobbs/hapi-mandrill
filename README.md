HAPI plugin that exposes mandrill api - used to send transactional emails.

## Usage
The key and templateNameMapping parameters are optional, but without a key nothing gets sent (useful for testing).

```Coffeescript

hapiMandrill = require 'hapi-mandrill'

pluginConf = [
    plugin: hapiMandrill
    options:
      senderName: "John Smith"
      senderEmail: "john@smith.com"
      key : null # Keep null for testing
      templateNameMapping: 
        "from" : "toInMandrill"
]

server.register pluginConf, (err) ->
  #...

```

## Send Mail
```Coffeescript

fnCallback = (err,result) ->
  # Do some stuff when done.

plugin = server.plugins['hapi-mandrill']

plugin.send("Angelina Jolie","angelina@jolie.com", {some: "payload"},"Hello Angelina","angelina-template", fnCallback)

```

## Logging
The plugin logs successful and failed sends. NOTE: If you want to disable this, or want different log tags let me know and I will make it customizable.

## Template Name Mapping
Mandrill templates are often managed by third parties, you don't want them to break a core functionaly without testing it first yourself. For that reason, you can define internal template names and transform them to whatever you want to use in mandrill. 
To do so, set the 'templateNameMap' object to internal : external pairs. If none is defined, or a
key is not found it will be passed verbatim.

## Exposed Properties
```Coffeescript
plugin = server.pack.plugins['hapi-mandrill']

plugin.mandrillClient # Note this is null if you do not pass a key in options
plugin.send(...)
plugin.templateNameMapping = {...}

```
