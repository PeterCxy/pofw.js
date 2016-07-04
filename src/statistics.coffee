fs = require "fs"
{argv} = require "./pofw"

statistics = {}
saved = false

save = ->
  if not saved
    fs.writeFile argv.statistics, JSON.stringify(statistics), (err) ->
      throw err if err?
      saved = true

setInterval save, 1 * 60 * 1000 # Save every minute

exports.RX = RX = "rx"
exports.TX = TX = "tx"

exports.setStatistics = setStatistics = (s) ->
  statistics = s

exports.increase = increase = (addr, type, len) ->
  throw new Error("Unknown type #{type}") if not type in [RX, TX]

  saved = false
  if not statistics[addr]?
    statistics[addr] = {}
  if not statistics[addr][type]?
    statistics[addr][type] = 0
  statistics[addr][type] += len
