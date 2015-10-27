promise = require 'bluebird'
request = require 'request'
crypto = require 'crypto'
uuid = require 'node-uuid'

API_URL = 'https://adbot.io/api'
TIMEOUT = 15e3

noop = ->
calcDigest = (time, secret, botKey, apiKey) ->
  crypto.createHash('md5').update([time, secret, botKey, apiKey].join('|')).digest('hex')


class Client

  constructor: (@key, @botId, @config = {}) ->
    # @botId can be key or id
    @config.apiUrl ||= API_URL
    @config.timeout ||= TIMEOUT
    @botId = parseInt(@botId, 10)


  emitEvent: (params, cb = noop) ->
    params.apiKey = @key
    p = promise.fromNode (cb) =>
      request.post("#{@config.apiUrl}/bots/#{@botId}/emit_event", {
        body: params
        json: true
        timeout: @config.timeout
      }, cb)
    .get(1)
    p.nodeify(cb)
    p

  partnerSync: (body, botProvider, cb = noop) ->
    {secret, time, action, digest} = body
    apiKey = @key
    botId = @botId
    p = promise.try ->
      unless (Date.now() / 1e3) <= (time + 60)
        return promise.reject('Invalid time')
      promise.fromNode (_cb) ->
        p = botProvider(_cb)
        if p?.then?
          promise.resolve(p).nodeify(_cb)
      .then (bot) ->
        unless bot
          return promise.reject('Bot does not found')
        {events, key} = bot
        _digest = calcDigest(time, secret, key, apiKey)
        unless _digest is digest
          return promise.reject('Bad digest')
        data = {secret: uuid.v4()}
        if action is 'enable'
          data.events = events
        if action is 'disable'
          data.success = true
        data.digest = calcDigest(time, data.secret, key, apiKey)
        data
    p.nodeify(cb)
    p

module.exports = (key, botId, config) ->
  new Client(key, botId, config)