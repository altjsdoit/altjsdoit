document.addEventListener "DOMContentLoaded", ->
  do ->
    a = new Promise (resolve, reject)->
      base64ToString getURLParameter(location.search, "js"), (a)-> resolve a
    b = new Promise (resolve, reject)->
      base64ToString getURLParameter(location.search, "html"), (a)-> resolve a
    c = new Promise (resolve, reject)->
      base64ToString getURLParameter(location.search, "css"), (a)-> resolve a
    Promise.all([a, b, c]).then ([js, html, css])->
      document.getElementById("jsCode").value = js
      document.getElementById("htmlCode").value = html
      document.getElementById("cssCode").value = css
      ###
      opt = {
        'theme': 'solarized dark',
        'lineNumbers': true,
        'matchBrackets': true,
        'electricChars': true,
        'persist': true,
        'styleActiveLine': true,
        'autoClearEmptyLines': true,
        'extraKeys': { 'Tab': 'indentSelection' },
      }
      a = CodeMirror.fromTextArea(document.getElementById("jsCode"), mix(opt, {mode:"javascript"}))
      b = CodeMirror.fromTextArea(document.getElementById("htmlCode"), mix(opt, {mode:"htmlmixed"}))
      c = CodeMirror.fromTextArea(document.getElementById("cssCode"), mix(opt, {mode:"css"}))
      ###

  document.getElementById("makeLink").addEventListener "click", ->
    a = new Promise (resolve, reject)->
      stringToBase64 document.getElementById("jsCode").value, (a)-> resolve encodeURIComponent a
    b = new Promise (resolve, reject)->
      stringToBase64 document.getElementById("htmlCode").value, (a)-> resolve encodeURIComponent a
    c = new Promise (resolve, reject)->
      stringToBase64 document.getElementById("cssCode").value, (a)-> resolve encodeURIComponent a
    Promise.all([a, b, c]).then ([js, html, css])->
      link = location.href.split("?")[0]+ "?html="+html+"&css="+css+"&js="+js
      document.getElementById("makedLink").value = link
      history.pushState(null, null, link)

  document.getElementById("run").addEventListener "click", ->
    js   = document.getElementById("jsCode").value
    html = document.getElementById("htmlCode").value
    css  = document.getElementById("cssCode").value
    toDataURL make(js, html, css), "text/html", (a)->
      document.getElementById("sandbox").setAttribute "src", a

  document.getElementById("download").addEventListener "click", ->
    js   = document.getElementById("jsCode").value
    html = document.getElementById("htmlCode").value
    css  = document.getElementById("cssCode").value
    toDataURL make(js, html, css), "text/plain", (a)->
      location.href = a

make = (js, html, css)->
  """
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8" />
    <style>#{css}</style>
  </head>
  <body>
    #{html}
    <script>#{js+"</"}script>
  </body>
  </html>
  """

mix = (a, b)->
  c = {}
  for key, val of a then c[key] = val
  for key, val of b then c[key] = val
  c

getURLParameter = (query, name)->
  decodeURIComponent(
    (new RegExp(
       '[?|&]' + name + '=' + '([^&;]+?)(&|#|;|$)')
    .exec(query)||["",""])[1]
    .replace(/\+/g, '%20')) or ""

base64ToString = (base64, cb)->
  tmp = base64.split(',')
  mimeString = tmp[0].split(':')[1].split(';')[0]
  byteString = atob(tmp[1] or "")
  ab = new ArrayBuffer(byteString.length)
  ia = new Uint8Array(ab)
  for i in [0..byteString.length] then ia[i] = byteString.charCodeAt(i)
  reader = new window.FileReader()
  reader.readAsText(new Blob([ab], {type: mimeString}))
  reader.onloadend = ->
    cb(reader.result)
  reader.onerror = (err)-> throw new Error err

stringToBase64 = (str, cb)->
  toDataURL(str, "text/plain", cb)

toDataURL = (data, mime, cb)->
  reader = new window.FileReader()
  reader.readAsDataURL(new Blob([data], {type: mime}))
  reader.onloadend = -> cb(reader.result)
  reader.onerror = (err)-> throw new Error err
