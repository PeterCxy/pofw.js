log = require "winston"
dgram = require "dgram"
main = require "./pofw"
{RX, TX, increase} = require "./statistics"

exports.startForwardingUDP = startForwardingUDP = (from_proto, from_ip, from_port, to_proto, to_ip, to_port) ->
  local = "#{from_ip}:#{from_port}"
  serverAddr = {}
  server = dgram.createSocket from_proto
  server.bind from_port, from_ip, ->
    main.onServerUp()
    log.info "listening on [#{from_proto}] #{from_ip}:#{from_port}"
    serverAddr = server.address()
  server.on "message", (msg, rinfo) ->
    increase from_proto, local, TX, msg.length
    {address, port} = rinfo
    socket = dgram.createSocket to_proto
    socket.send msg, 0, msg.length, to_port, to_ip, (err) ->
      if err? and err != 0
        log.error err
        socket = msg = rinfo = null
        global.gc() if global.gc?

    # Allow one packet to come back for each outgoing packet
    socket.on "message", (msg, rinfo) ->
      increase from_proto, local, RX, msg.length
      server.send msg, 0, msg.length, port, address, (err) ->
        log.error err if err? and err != 0
        try
          socket.close()
        catch e
          log.error e
        finally
          log.info "[#{from_proto} <-> #{to_proto}] #{address}:#{port} <---> #{serverAddr.address}:#{serverAddr.port} ====> #{serverAddr.address}:#{serverAddr.port} <---> #{rinfo.address}:#{rinfo.port}"
        socket = msg = rinfo = null
        global.gc() if global.gc?

    socket.on "error", (err) ->
      log.error err

  server.on "error", (err) ->
    log.error err

  process.once 'SIGHUP', ->
    server.close main.onServerClose
