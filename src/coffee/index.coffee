document.addEventListener "DOMContentLoaded", ->
  do ->
    {js:a, html:b, css:c} = decodeURIQuery(location.search)
    decodeDataURI a, (js)->
      decodeDataURI b, (html)->
        decodeDataURI c, (css)->
          document.getElementById("jsCode").value   = js   or ""
          document.getElementById("htmlCode").value = html or ""
          document.getElementById("cssCode").value  = css  or ""


  document.getElementById("makeLink").addEventListener "click", ->
    {js, html, css} = getData(document)
    encodeDataURI js, "text/plain", (a)->
      encodeDataURI html, "text/plain", (b)->
        encodeDataURI css, "text/plain", (c)->
          url = location.href.split("?")[0] + encodeURIQuery({js:a, html:b, css:c})
          document.getElementById("makedLink").value = url
          history.pushState(null, null, url)
          console.log url.length

  document.getElementById("run").addEventListener "click", ->
    html = makeHTML(getData(document))
    encodeDataURI html, "text/html", (a)-> document.getElementById("sandbox").setAttribute "src", a

decodeDataURI = (base64, cb)->
  if !base64? then return setTimeout cb
  tmp = base64.split(',')
  mimeString = tmp[0].split(':')[1].split(';')[0]
  byteString = atob(tmp[1])
  ab = new ArrayBuffer(byteString.length)
  ia = new Uint8Array(ab)
  for i in [0..byteString.length]
    ia[i] = byteString.charCodeAt(i)
  reader = new FileReader()
  reader.readAsText(new Blob([ab], {type: mimeString}))
  reader.onloadend = -> cb(reader.result)

encodeDataURI = (data, mime, cb)->
  reader = new FileReader()
  reader.readAsDataURL(new Blob([data], {type: mime}))
  reader.onloadend = -> cb(reader.result)
  reader.onerror = (err)-> throw new Error err

decodeURIQuery = (str)->
  str
    .replace("?", "")
    .split("&")
    .map((a)->
      b = a.split("=")
      [b[0], b.slice(1).join("=")]
    )
    .reduce(((a, b)->
      a[b[0]] = decodeURIComponent(b[1])
      a
    ), {})

encodeURIQuery = (o)->
  "?"+((key+"="+encodeURIComponent(val) for key, val of o).join("&"))

getData = (_document)->
  js   = _document.getElementById("jsCode").value   or ""
  html = _document.getElementById("htmlCode").value or ""
  css  = _document.getElementById("cssCode").value  or ""
  {js, html, css}

makeHTML = ({js, html, css})->
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
