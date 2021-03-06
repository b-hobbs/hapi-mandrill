(function() {
  var Hoek, i18n, mandrill, _;

  _ = require('underscore');

  mandrill = require('mandrill-api/mandrill');

  Hoek = require('hoek');

  i18n = require('./i18n');


  /*
  Registers the plugin.
   */

  module.exports.register = function(server, options, cb) {
    var convertVars, defaults, mandrillClient, send, sendTemplate, templateNameMapping;
    if (options == null) {
      options = {};
    }
    Hoek.assert(options.senderName, i18n.optionsSenderNameRequired);
    Hoek.assert(options.senderEmail, i18n.optionsSenderEmailRequired);
    defaults = {
      verbose: false,
      templateNameMap: {}
    };
    options = Hoek.applyToDefaults(defaults, options);
    mandrillClient = null;
    templateNameMapping = options.templateNameMap;

    /*
    This is lenient to simplify testing.
     */
    if (options.key) {
      mandrillClient = new mandrill.Mandrill(options.key);
      if (options.verbose) {
        console.log("Mandrill active with " + options.key);
      }
    } else {
      if (options.verbose) {
        console.log("Mandrill disabled - no key");
      }
      server.log(['configuration', 'warning'], i18n.emailSendDisabled);
    }
    convertVars = function(vars) {
      var k, newVars, _i, _len, _ref;
      newVars = [];
      _ref = _.keys(vars);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        k = _ref[_i];
        newVars.push({
          name: k,
          content: vars[k]
        });
      }
      return newVars;
    };
    send = function(receiverEmail, htmlMessage, subject, payload, cb2) {
      var error, global_merge_vars, merge_vars, message, sendTemplateOptions, success;
      if (payload == null) {
        payload = {};
      }
      if (cb2 == null) {
        cb2 = function() {};
      }
      if (options.verbose) {
        console.log("Sending to: " + receiverEmail);
      }
      if (options.verbose) {
        console.log("payload: " + (JSON.stringify(payload)));
      }
      if (payload.global_merge_vars) {
        global_merge_vars = payload.global_merge_vars;
        if (options.global_merge_vars) {
          global_merge_vars = _.extend(options.global_merge_vars, global_merge_vars);
        }
        global_merge_vars = convertVars(global_merge_vars);
      } else if (options.global_merge_vars) {
        global_merge_vars = options.global_merge_vars;
        global_merge_vars = convertVars(global_merge_vars);
      }
      if (payload.merge_vars) {
        merge_vars = payload.merge_vars;
        merge_vars = convertVars(merge_vars);
      }
      message = {
        html: htmlMessage,
        from_email: options.senderEmail,
        from_name: options.senderName,
        subject: subject,
        to: [
          {
            email: receiverEmail
          }
        ]
      };
      if (options.message) {
        message = _.extend(options.message, message);
      }
      if (payload.message) {
        message = _.extend(message, payload.message);
      }
      sendTemplateOptions = {
        message: message,
        async: options.async || false,
        ip_pool: options.ip_pool ? options.ip_pool : void 0,
        send_at: options.send_at ? payload.send_at : void 0
      };
      if (global_merge_vars) {
        sendTemplateOptions.message.global_merge_vars = global_merge_vars;
      }
      if (merge_vars) {
        sendTemplateOptions.message.merge_vars = merge_vars;
      }
      if (options.verbose) {
        console.log("requestJSON: " + (JSON.stringify(sendTemplateOptions)));
      }
      success = function(result) {
        if (options.verbose) {
          console.log("Mandrill success: " + (JSON.stringify(result)));
        }
        server.log(['mandrill', 'email-sent'], i18n.emailQueuedSuccess, result);
        return cb2(null, result);
      };
      error = function(err) {
        if (options.verbose) {
          console.log("Mandrill error: " + (JSON.stringify(err)));
        }
        server.log(['mandrill', 'email-not-sent', 'error'], i18n.emailNotQueuedFailure, err);
        return cb2(err);
      };
      if (mandrillClient) {
        if (options.verbose) {
          console.log("Sending to Mandrill: " + (JSON.stringify(sendTemplateOptions)));
        }
        return mandrillClient.messages.send(sendTemplateOptions, success, error);
      } else {
        if (options.verbose) {
          console.log("Faking mandrill send");
        }
        return success({});
      }
    };
    sendTemplate = function(receiverEmail, templateName, payload, cb2) {
      var error, global_merge_vars, merge_vars, message, sendTemplateOptions, success, templateContent;
      if (payload == null) {
        payload = {};
      }
      if (cb2 == null) {
        cb2 = function() {};
      }
      if (options.verbose) {
        console.log("Sending to: " + receiverEmail + " / " + templateName);
      }
      if (options.verbose) {
        console.log("payload: " + (JSON.stringify(payload)));
      }
      templateName = templateNameMapping[templateName] || templateName;
      templateContent = payload.templateContent || [];
      templateContent = convertVars(templateContent);
      if (payload.global_merge_vars) {
        global_merge_vars = payload.global_merge_vars;
        if (options.global_merge_vars) {
          global_merge_vars = _.extend(options.global_merge_vars, global_merge_vars);
        }
        global_merge_vars = convertVars(global_merge_vars);
      } else if (options.global_merge_vars) {
        global_merge_vars = options.global_merge_vars;
        global_merge_vars = convertVars(global_merge_vars);
      }
      if (payload.merge_vars) {
        merge_vars = payload.merge_vars;
        merge_vars = convertVars(merge_vars);
      }
      message = {
        to: [
          {
            email: receiverEmail
          }
        ]
      };
      if (options.message) {
        message = _.extend(options.message, message);
      }
      if (payload.message) {
        message = _.extend(message, payload.message);
      }
      sendTemplateOptions = {
        template_name: templateName,
        template_content: templateContent,
        message: message,
        async: options.async || false,
        ip_pool: options.ip_pool ? options.ip_pool : void 0,
        send_at: options.send_at ? payload.send_at : void 0
      };
      if (global_merge_vars) {
        sendTemplateOptions.message.global_merge_vars = global_merge_vars;
      }
      if (merge_vars) {
        sendTemplateOptions.message.merge_vars = merge_vars;
      }
      if (options.verbose) {
        console.log("requestJSON: " + (JSON.stringify(sendTemplateOptions)));
      }
      success = function(result) {
        if (options.verbose) {
          console.log("Mandrill success: " + (JSON.stringify(result)));
        }
        server.log(['mandrill', 'email-sent'], i18n.emailQueuedSuccess, result);
        return cb2(null, result);
      };
      error = function(err) {
        if (options.verbose) {
          console.log("Mandrill error: " + (JSON.stringify(err)));
        }
        server.log(['mandrill', 'email-not-sent', 'error'], i18n.emailNotQueuedFailure, err);
        return cb2(err);
      };
      if (mandrillClient) {
        if (options.verbose) {
          console.log("Sending to Mandrill: " + (JSON.stringify(sendTemplateOptions)));
        }
        return mandrillClient.messages.sendTemplate(sendTemplateOptions, success, error);
      } else {
        if (options.verbose) {
          console.log("Faking mandrill send");
        }
        return success({});
      }
    };
    server.expose('mandrillClient', mandrillClient);
    server.expose('sendTemplate', sendTemplate);
    server.expose('send', send);
    server.expose('templateNameMapping', templateNameMapping);
    return cb();
  };

  module.exports.register.attributes = {
    pkg: require('../package.json')
  };

}).call(this);

//# sourceMappingURL=index.js.map
