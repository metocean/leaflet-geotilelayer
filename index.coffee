request = require 'superagent'

L.GeoTileLayer = L.GridLayer.extend
  options: maxZoom: 18

  initialize: (url, options) ->
    @_url = url
    @_tileCache = {}
    options = L.setOptions @, options

  createTile: (coords, done) ->
    layer = @
    tile = document.createElement 'span'

    params =
      x: coords.x
      y: coords.y
      z: @_tileZoom

    requestparams =
      x: params.x
      y: params.y
      z: params.z

    # scale back the request if past the zoom level
    while requestparams.z > @options.zoom
      requestparams.x = Math.floor requestparams.x / 2
      requestparams.y = Math.floor requestparams.y / 2
      requestparams.z -= 1

    params.url = L.Util.template @_url, requestparams
    params.size = @getTileSize()

    if @_tileCache[params.url]?
      geo = @_tileCache[params.url]
      layer.options.render tile, params, geo
      setTimeout ->
        done null, tile
      , 1
    else
      request
        .get params.url
        .set 'Accept', 'application/json'
        .end (err, res) ->
          return done err, tile if err?
          layer._tileCache[params.url] = res.body
          layer.options.render tile, params, res.body
          done null, tile

    tile

module.exports = (url, options) ->
  new L.GeoTileLayer url, options