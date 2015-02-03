_ = require 'underscore'
mandrill = require 'mandrill-api/mandrill'
Hoek = require 'hoek'
i18n = require './i18n'

###
Registers the plugin.
###
module.exports.register = (server, options = {}, cb) ->
  Hoek.assert options.senderName, i18n.optionsSenderNameRequired
  Hoek.assert options.senderEmail, i18n.optionsSenderEmailRequired

  defaults =
    templateNameMap : {}
    verbose : false
    global_merge_vars : {}

  options = Hoek.applyToDefaults defaults, options

  mandrillClient = null
  templateNameMapping = options.templateNameMap

  ###
  This is lenient to simplify testing.
  ###
  if options.key
    mandrillClient = new mandrill.Mandrill options.key
    console.log "Mandrill active with #{options.key}" if options.verbose
  else
    console.log "Mandrill disabled - no key" if options.verbose
    server.log ['configuration','warning'], i18n.emailSendDisabled

  sendTemplate = (receiverEmail, templateName, templateVars = {},cb2 = ->) ->
    console.log "Sending to: #{receiverEmail} / #{templateName}" if options.verbose
    console.log "templateVars: #{JSON.stringify(templateVars)}" if options.verbose

    global_merge_vars = templateVars.global_merge_vars
    global_merge_vars = _.union(global_merge_vars, options.global_merge_vars) if options.global_merge_vars
    merge_vars = templateVars.merge_vars

    delete templateVars.global_merge_vars
    delete templateVars.merge_vars

    templateContent = []
    for k in _.keys templateVars
      templateContent.push
        name : k
        content: templateVars[k]

    templateName = templateNameMapping[templateName] || templateName # If it is mapped, take the mapped one, otherwise pass it 1:1

    console.log "Mapped templateName: #{templateName}" if options.verbose

    sendTemplateOptions =
      template_name: templateName
      template_content: templateContent
      async: true
      message:
        to: [
            email: receiverEmail
          ]
        track_opens: true
        auto_text: true
        auto_html: true
        inline_css: true

    sendTemplateOptions.message.global_merge_vars = global_merge_vars if global_merge_vars
    sendTemplateOptions.message.merge_vars = merge_vars if merge_vars

    success = (result) ->
      console.log "Mandrill success: #{JSON.stringify(result)}" if options.verbose

      server.log ['mandrill','email-sent'],i18n.emailQueuedSuccess, result
      cb2 null,result

    error = (err) ->
      console.log "Mandrill error: #{JSON.stringify(err)}" if options.verbose

      server.log ['mandrill','email-not-sent','error'],i18n.emailNotQueuedFailure, err
      cb2 err

    if mandrillClient
      console.log "Sending to Mandrill: #{JSON.stringify(sendTemplateOptions)}" if options.verbose
      mandrillClient.messages.sendTemplate sendTemplateOptions, success,error
    else
      console.log "Faking mandrill send" if options.verbose
      success {} # Mock mode, need to think about result

  server.expose 'mandrillClient', mandrillClient
  server.expose 'sendTemplate', sendTemplate
  #server.expose 'send', send
  server.expose 'templateNameMapping', templateNameMapping

  cb()

module.exports.register.attributes =
  pkg: require '../package.json'

