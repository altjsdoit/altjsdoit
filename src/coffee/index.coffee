document.addEventListener "DOMContentLoaded", ->
  do ->
    {zip, altjs, althtml, altcss} = decodeURIQuery(location.search)
    {js, html, css} = unzipDataURI(zip)
    document.getElementById("altJS"   ).value = altjs   or "JavaScript"
    document.getElementById("altHTML" ).value = althtml or "HTML"
    document.getElementById("altCSS"  ).value = altcss  or "CSS"
    document.getElementById("jsCode"  ).value = js      or ""
    document.getElementById("htmlCode").value = html    or ""
    document.getElementById("cssCode" ).value = css     or ""

  document.getElementById("makeLink").addEventListener "click", ->
    opt =
      zip:     zipDataURI(getData(document))
      altjs:   document.getElementById("altJS"  ).value
      althtml: document.getElementById("altHTML").value
      altcss:  document.getElementById("altCSS" ).value
    url = location.href.split("?")[0] + encodeURIQuery(opt)
    document.getElementById("makedLink").value = url
    history.pushState(null, null, url)
    console.log url.length

  document.getElementById("run").addEventListener "click", ->
    {js, html, css} = getData(document)
    _js   = compile document.getElementById("altJS"  ).value, js
    _html = compile document.getElementById("altHTML").value, html
    _css  = compile document.getElementById("altCSS" ).value, css
    html = makeHTML({js:_js, html:_html, css:_css})
    encodeDataURI html, "text/html", (a)-> document.getElementById("sandbox").setAttribute "src", a

compile = (type, code)->
  switch type
    when "CoffeeScript" then CoffeeScript.compile(code)
    else code

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

zipDataURI = ({js, html, css})->
  zip = new JSZip()
  zip.file("js", js)
  zip.file("html", html)
  zip.file("css", css)
  zip.generate({compression: "DEFLATE"})

unzipDataURI = (data)->
  try
    zip = new JSZip()
    zip.load(data,{base64: true})
    js = zip.file("js")?.asText()
    html = zip.file("html")?.asText()
    css = zip.file("css")?.asText()
  {js, html, css}

encodeDataURI = (data, mime, cb)->
  reader = new FileReader()
  reader.readAsDataURL(new Blob([data], {type: mime}))
  reader.onloadend = -> cb(reader.result)
  reader.onerror = (err)-> throw new Error err

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

encodeURIQuery = (o)->
  "?"+((key+"="+encodeURIComponent(val) for key, val of o).join("&"))

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
