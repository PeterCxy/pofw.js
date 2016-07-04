log = require "winston"
net = require "net"
{RX, TX, increase} = require "./statistics"

exports.startForwardingTCP = startForwardingTCP = (from_ip, from_port, to_ip, to_port) ->
  local = "#{from_ip}:#{from_port}"
  server = net.createServer (c) =>

    #log.info "new connection from [tcp] #{c.address().address}:#{c.address().port}"
    s = net.createConnection to_port, to_ip

    s.on "connect", =>
      log.info "[tcp] #{c.remoteAddress}:#{c.remotePort} <---> #{c.localAddress}:#{c.localPort} ====> #{s.localAddress}:#{s.localPort} <---> #{s.remoteAddress}:#{s.remotePort}"
      ended = false
      endAll = ->
        if not ended
            ended = true
            s.end()
            c.end()

      # Tunnel data between our client and the remote server
      c.on "data", (data) =>
        increase local, TX, data.length
        s.write data if not ended
      s.on "data", (data) =>
        increase local, RX, data.length
        c.write data if not ended

      # Handle end and error events
      c.on "error", (err) =>
        log.error err
        endAll()
        c.destroy()
      s.on "error", (err) =>
        log.error err
        endAll()
        s.destroy()
      c.on "end", =>
        endAll()
      s.on "end", =>
        endAll()

  server.on "error", (err) =>
    log.error err
  server.listen from_port, from_ip, 511, =>
    log.info "listening on [tcp] #{from_ip}:#{from_port}"
