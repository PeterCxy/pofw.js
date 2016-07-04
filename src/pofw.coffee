SUPPORTED_PROTOCOLS = ["tcp", "tcp4", "tcp6", "udp", "udp4", "udp6"]

{argv} = require("yargs")
  .usage("Usage: $0 -c [config]")
  .demand("c")
  .default({"c": "config.json"})
  .alias("c", "config")
  .describe("c", "Path to the configuration file in JSON format")
  .help("h")
  .alias("h", "help")
fs = require "fs"
{startForwardingTCP} = require "./tcp"
{startForwardingUDP} = require "./udp"

# Load the configuration file
s = fs.createReadStream(argv.config)
config = ""
s.on "data", (data) ->
  config += data
s.on "end", ->
  config = JSON.parse config
  for c in config
    if not (c.from_protocol? and c.from_ip? and c.from_port? and c.to_ip? and c.to_port?)
      throw new Error("You must provide at least from_protocol, from_ip, from_port, to_ip, to_port")

    if not c.to_protocol?
      # to_protocol is by default the same as from_protocol
      c.to_protocol = c.from_protocol

    if not (c.from_protocol in SUPPORTED_PROTOCOLS and c.to_protocol in SUPPORTED_PROTOCOLS)
      throw new Error("Only #{SUPPORTED_PROTOCOLS} are supported")

    if c.from_protocol is "udp"
      # By default we assume IPv4
      c.from_protocol = "udp4"
    if c.to_protocol is "udp"
      c.to_protocol = "udp4"

    if c.from_protocol[0..2] != c.to_protocol[0..2]
      throw new Error("Conversion between UDP and TCP is not supported for now.")

    if c.from_protocol.startsWith "tcp"
      startForwardingTCP c.from_ip, c.from_port, c.to_ip, c.to_port
    else if c.from_protocol.startsWith "udp"
      startForwardingUDP c.from_protocol, c.from_ip, c.from_port, c.to_protocol, c.to_ip, c.to_port
