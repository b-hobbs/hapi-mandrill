assert = require 'assert'
should = require 'should'
index = require '../lib/index'
_ = require 'underscore'

loadServer = require './support/load-server'

describe 'WHEN index has been loaded', ->
  server = null
  mandrillPlugin = null

  describe 'with server setup', ->
    beforeEach (cb) ->
      loadServer (err,serverResult) ->
        return cb err if err
        server = serverResult
        mandrillPlugin = server.plugins['hapi-mandrill']
        cb null

    it 'should send email', (cb) ->
      templateVars =
        resetlink: "<a href=\"http://test.com\">Reset Password</a>"
        token: "<span>\"123456789\"</span>"
      mandrillPlugin.sendTemplate "martin@wawrusch.com", templateVars, "passwordReset", (err,result) ->

        should.not.exist err
        should.exist result

        cb null

