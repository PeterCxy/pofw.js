# Setup cleanup job
exports.cleanupJob = (callback) ->
  process.on "cleanup", callback
  process.on "exit", ->
    process.emit "cleanup"
  process.on "SIGINT", ->
    process.exit 2
