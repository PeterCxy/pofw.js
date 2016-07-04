log = require "winston"
net = require "net"
{RX, TX, increase} = require "./statistics"

exports.startForwardingTCP = startForwardingTCP = (from_ip, from_port, to_ip, to_port) ->
  local = "#{from_ip}:#{from_port}"
  server = net.createServer (c) ->
    c = c.setNoDelay true
    s = net.createConnection to_port, to_ip
        .setNoDelay true

    s.on "connect", ->
      log.info "[tcp] #{c.remoteAddress}:#{c.remotePort} <---> #{c.localAddress}:#{c.localPort} ====> #{s.localAddress}:#{s.localPort} <---> #{s.remoteAddress}:#{s.remotePort}"
      ended = false
      endAll = ->
        if not ended
            ended = true
            s.end()
            c.end()
            s.destroy()
            c.destroy()
            s = c = endAll = null

            global.gc() if global.gc?

            return

      # Tunnel data between our client and the remote server
      c.on "data", (data) ->
        increase "tcp", local, TX, data.length
        if not ended
          c.pause()
          s.write data, ->
            c.resume() if not ended
      s.on "data", (data) ->
        increase "tcp", local, RX, data.length
        if not ended
          s.pause()
          c.write data, ->
            s.resume() if not ended

      # Handle end and error events
      c.on "error", (err) ->
        log.error err
        endAll()
      s.on "error", (err) ->
        log.error err
        endAll()
      c.on "end", ->
        endAll()
      s.on "end", ->
        endAll()

  server.on "error", (err) ->
    log.error err
  server.listen from_port, from_ip, 511, ->
    log.info "listening on [tcp] #{from_ip}:#{from_port}"
