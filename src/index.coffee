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
    verbose : false
    templateNameMap : {}

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

  convertVars = (vars) ->
    newVars = []
    for k in _.keys vars
      newVars.push
        name : k
        content: vars[k]
    newVars

  send = (receiverEmail, htmlMessage, subject, payload = {},cb2 = ->) ->
    console.log "Sending to: #{receiverEmail}" if options.verbose
    console.log "payload: #{JSON.stringify(payload)}" if options.verbose

    if payload.global_merge_vars
      global_merge_vars = payload.global_merge_vars
      global_merge_vars = _.extend options.global_merge_vars, global_merge_vars if options.global_merge_vars
      global_merge_vars = convertVars global_merge_vars
    else if options.global_merge_vars
      global_merge_vars = options.global_merge_vars
      global_merge_vars = convertVars global_merge_vars

    if payload.merge_vars
      merge_vars = payload.merge_vars
      merge_vars = convertVars merge_vars

    message =
      html: htmlMessage
      from_email: options.senderEmail
      from_name: options.senderName
      subject: subject
      to: [
          email: receiverEmail
        ]
    message = _.extend options.message, message if options.message
    message = _.extend message, payload.message if payload.message

    sendTemplateOptions =
      message: message
      async: options.async || false
      ip_pool : options.ip_pool if options.ip_pool
      send_at : payload.send_at if options.send_at


    sendTemplateOptions.message.global_merge_vars = global_merge_vars if global_merge_vars
    sendTemplateOptions.message.merge_vars = merge_vars if merge_vars

    console.log "requestJSON: #{JSON.stringify(sendTemplateOptions)}" if options.verbose

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
      mandrillClient.messages.send sendTemplateOptions, success, error
    else
      console.log "Faking mandrill send" if options.verbose
      success {} # Mock mode, need to think about result

  sendTemplate = (receiverEmail, templateName, payload = {},cb2 = ->) ->
    console.log "Sending to: #{receiverEmail} / #{templateName}" if options.verbose
    console.log "payload: #{JSON.stringify(payload)}" if options.verbose

    templateName = templateNameMapping[templateName] || templateName # If it is mapped, take the mapped one, otherwise pass it 1:1

    templateContent = payload.templateContent || []
    templateContent = convertVars templateContent

    if payload.global_merge_vars
      global_merge_vars = payload.global_merge_vars
      global_merge_vars = _.extend options.global_merge_vars, global_merge_vars if options.global_merge_vars
      global_merge_vars = convertVars global_merge_vars
    else if options.global_merge_vars
      global_merge_vars = options.global_merge_vars
      global_merge_vars = convertVars global_merge_vars

    if payload.merge_vars
      merge_vars = payload.merge_vars
      merge_vars = convertVars merge_vars

    message =
      to: [
          email: receiverEmail
        ]
    message = _.extend options.message, message if options.message
    message = _.extend message, payload.message if payload.message

    sendTemplateOptions =
      template_name: templateName
      template_content: templateContent
      message: message
      async: options.async || false
      ip_pool : options.ip_pool if options.ip_pool
      send_at : payload.send_at if options.send_at


    sendTemplateOptions.message.global_merge_vars = global_merge_vars if global_merge_vars
    sendTemplateOptions.message.merge_vars = merge_vars if merge_vars

    console.log "requestJSON: #{JSON.stringify(sendTemplateOptions)}" if options.verbose

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
      mandrillClient.messages.sendTemplate sendTemplateOptions, success, error
    else
      console.log "Faking mandrill send" if options.verbose
      success {} # Mock mode, need to think about result

  server.expose 'mandrillClient', mandrillClient
  server.expose 'sendTemplate', sendTemplate
  server.expose 'send', send
  server.expose 'templateNameMapping', templateNameMapping

  cb()

module.exports.register.attributes =
  pkg: require '../package.json'

