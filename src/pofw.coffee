SUPPORTED_PROTOCOLS = ["tcp", "tcp4", "tcp6", "udp", "udp4", "udp6"]

{argv} = require("yargs")
  .usage("Usage: pofwjs -c [config] -s [statistics] -w [port]")
  .demand("c")
  .default("c", "config.json")
  .alias("c", "config")
  .describe("c", "Path to the configuration file in JSON format")
  .demand("s")
  .default("s", "statistics.json")
  .alias("s", "statistics")
  .describe("s", "Path to the statistics file where the program will write usage statistics into")
  .demand("w")
  .number("w")
  .default("w", "8080")
  .alias("w", "web")
  .describe("w", "Web server port for showing statistics page (0 = disable)")
  .help("h")
  .alias("h", "help")
exports.argv = argv
fs = require "fs"
log = require "winston"
{startForwardingTCP} = require "./tcp"
{startForwardingUDP} = require "./udp"
{setStatistics} = require "./statistics"

# Load the configuration file
fs.exists argv.config, (exists) ->
  if !exists
    log.error "#{argv.config} not found"
    argv.statistics = null
    process.exit 1

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

# Initialize the statistics
fs.exists argv.statistics, (exists) ->
  if exists
    r = fs.createReadStream(argv.statistics)
    statistics = ""
    r.on "data", (data) ->
      statistics += data
    r.on "end", ->
      statistics = JSON.parse statistics
      setStatistics statistics
