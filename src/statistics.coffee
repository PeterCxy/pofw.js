express = require "express"
path = require "path"
fs = require "fs"
log = require "winston"
{argv} = require "./pofw"
{generateTable} = require "./shared/stats"
{cleanupJob} = require "./cleanup"

statistics = {}
saved = false

save = (sync = false) ->
  return if !argv.statistics?
  if not saved
    if not sync
      fs.writeFile argv.statistics, JSON.stringify(statistics), (err) ->
        throw err if err?
        saved = true
    else
      log.info "Writing statistics in synchronous mode"
      fs.writeFileSync argv.statistics, JSON.stringify(statistics)

setInterval save, 1 * 60 * 1000 # Save every minute

# Save before exiting
cleanupJob ->
  log.info "Saving statistics before exiting"
  save true # Cannot do async jobs when exiting

exports.RX = RX = "rx"
exports.TX = TX = "tx"

exports.setStatistics = setStatistics = (s) ->
  statistics = s

exports.increase = increase = (protocol, addr, type, len) ->
  throw new Error("Unknown type #{type}") if not type in [RX, TX]

  saved = false
  if not statistics[protocol]?
    statistics[protocol] = {}
  if not statistics[protocol][addr]?
    statistics[protocol][addr] = {}
  if not statistics[protocol][addr][type]?
    statistics[protocol][addr][type] = 0
  statistics[protocol][addr][type] += len

# The web server
if argv.web > 0
  app = express()
  app.use express.static path.join __dirname + "/../static"
  app.use "/scripts", express.static path.join __dirname + "/shared"
  app.get "/", (req, res) ->
    s = fs.createReadStream path.join __dirname + "/../static/template.html"
    index = ""
    s.on "data", (data) ->
      index += data
    s.on "end", ->
      index = index.replace '{{placeholder}}', generateTable statistics
      res.send index
  app.get "/backend/stats", (req, res) ->
    res.send JSON.stringify statistics
  app.get "/backend/reset", (req, res) ->
    statistics = {}
    saved = false
    res.send JSON.stringify ok: true
  app.get "/backend/reload", (req, res) ->
    process.emit 'SIGHUP'
    res.send JSON.stringify ok: true
  app.listen argv.web, ->
    log.info "listening on [http] 127.0.0.1:#{argv.web}"
