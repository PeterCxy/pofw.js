log = require "winston"
dgram = require "dgram"

exports.startForwardingUDP = startForwardingUDP = (from_proto, from_ip, from_port, to_proto, to_ip, to_port) ->
  serverAddr = {}
  server = dgram.createSocket from_proto
  server.bind from_port, from_ip, =>
    log.info "listening on [#{from_proto}] #{from_ip}:#{from_port}"
    serverAddr = server.address()
  server.on "message", (msg, rinfo) =>
    {address, port} = rinfo
    socket = dgram.createSocket to_proto
    socket.send msg, 0, msg.length, to_port, to_ip, (err) =>
      log.error err if err? and err != 0

    # Allow one packet to come back for each outgoing packet
    socket.on "message", (msg, rinfo) =>
      server.send msg, 0, msg.length, port, address, (err) =>
        log.error err if err? and err != 0
        try
          socket.close()
        catch e
          log.error e
        finally
          log.info "[#{from_proto} <-> #{to_proto}] #{address}:#{port} <---> #{serverAddr.address}:#{serverAddr.port} ====> #{serverAddr.address}:#{serverAddr.port} <---> #{rinfo.address}:#{rinfo.port}"

    socket.on "error", (err) =>
      log.error err

  server.on "error", (err) =>
    log.error err