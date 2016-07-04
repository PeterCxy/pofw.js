# This file is shared between the browser and the backend

generateTable = (statistics) ->
  ret = '''
  <div class="row header">
    <div class="cell">Protocol</div>
    <div class="cell">Address</div>
    <div class="cell">Rx</div>
    <div class="cell">Tx</div>
  </div>
  '''

  for protocol, data of statistics
    for addr, info of data
      ret += """
      <div class="row">
        <div class="cell">#{protocol.toUpperCase()}</div>
        <div class="cell">#{addr}</div>
        <div class="cell">#{formatNumber info.rx}</div>
        <div class="cell">#{formatNumber info.tx}</div>
      </div>
      """

  return ret

formatNumber = (num) ->
  num = 0 if !num? or num < 0
  if num >= 1024 * 1024 * 1024 * 1024
    "#{(num / 1024 / 1024 / 1024 / 1024).toFixed 3} TiB"
  else if num >= 1024 * 1024 * 1024
    "#{(num / 1024 / 1024 / 1024).toFixed 3} GiB"
  else if num >= 1024 * 1024
    "#{(num / 1024 / 1024).toFixed 3} MiB"
  else if num >= 1024
    "#{(num / 1024).toFixed 3} KiB"
  else
    "#{num.toFixed 3} B"

if module?
  # Add to module.exports if running in Node.JS
  exports.generateTable = generateTable
else
  # Hurray! We are in a browser!
  httpGetAsync = (url, callback) ->
    xmlHttp = new XMLHttpRequest()
    xmlHttp.onreadystatechange = =>
      if xmlHttp.readyState == 4 and xmlHttp.status == 200
        callback xmlHttp.responseText
    xmlHttp.open "GET", url, true
    xmlHttp.send null

  update = ->
    httpGetAsync "/backend/stats", (res) ->
      document.getElementById("table").innerHTML = generateTable JSON.parse res

  setInterval update, 1 * 5 * 1000 # Update every 5 seconds
