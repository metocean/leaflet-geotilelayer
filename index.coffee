request = require 'superagent'

L.GeoTileLayer = L.GridLayer.extend
  options: maxZoom: 18

  initialize: (url, options) ->
    @_url = url
    @_geoCache = {}
    options = L.setOptions @, options

    if options.unload?
      @on 'tileunload', (e) ->
        params = @_generateParams e.coords
        options.unload.call @, e.tile, params, @_geoCache[params.url] ? null

  _update: (center) ->
    if @options.update?
      @options.update.call @
    L.GridLayer.prototype._update.call @, center

  _generateParams: (coords) ->
    params =
      x: coords.x
      y: coords.y
      z: coords.z

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
    params.key = "#{params.x},#{params.y},#{params.z}"

    params

  createTile: (coords, done) ->
    params = @_generateParams
      x: coords.x
      y: coords.y
      z: @_tileZoom

    layer = @
    tile = document.createElement 'span'

    if @_geoCache[params.url]?
      geo = @_geoCache[params.url]
      layer.options.render.call @, tile, params, geo
      setTimeout ->
        done null, tile
      , 1
    else
      request
        .get params.url
        .set 'Accept', 'application/json'
        .end (err, res) ->
          return done err, tile if err?
          layer._geoCache[params.url] = res.body
          layer.options.render.call layer, tile, params, res.body
          done null, tile

    tile

module.exports = (url, options) ->
  new L.GeoTileLayer url, options