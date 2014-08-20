express   = require 'express'
logfmt    = require 'logfmt'
Fulcrum   = require 'fulcrum-app'
distance  = require 'turf-distance'
point     = require 'turf-point'

constants = require './constants'

port = Number process.env.PORT or 5000
api_key = constants.fulcrum_api_key

app = express()
app.use logfmt.requestLogger()
app.use express.bodyParser()
app.use '/assets', express.static(__dirname + '/assets')

app.engine 'hamlc', require('haml-coffee').__express

fulcrum = new Fulcrum({api_key: api_key})

app.get '/', (req, resp) ->
  resp.render 'index.hamlc', {}

app.get '/current.geojson', (req, resp) ->
  callback = (error, records) ->
    if error
      console.log error
      resp.send 'Error'
    record = records.records[0]
    feature = recordToFeature record
    resp.json feature

  search_options =
    form_id       : constants.form_id
    newest_first  : 1
    per_page      : 1
    page          : 1
  fulcrum.records.search search_options, callback

app.get '/:time(day|month|week).geojson', (req, resp) ->
  callback = (error, records) ->
    if error
      console.log error
      resp.send 'Error'
    else
      feature_collection =
        type      : 'FeatureCollection'
        features  : records.records.map((record) -> recordToFeature(record))
      resp.json feature_collection

  now         = new Date()
  now_seconds = Math.floor(now.getTime() / 1000)

  if req.params.time is 'day'
    seconds_ago = 24 * 60 * 60
  else if req.params.time is 'week'
    seconds_ago = 7 * 24 * 60 * 60
  else  # month
    seconds_ago = 31 * 24 * 60 * 60

  updated_since = now_seconds - seconds_ago

  search_options =
    form_id       : constants.form_id
    updated_since : updated_since
  fulcrum.records.search search_options, callback

app.post '/', (req, resp) ->
  payload = req.body
  processPayload payload
  resp.send 'Thanks. You\'re the best!'

app.listen port, ->
  console.log "Listening on port: #{port}"

recordToFeature = (record) ->
  geometry =
    type        : 'Point'
    coordinates : [record.longitude, record.latitude]
  properties =
    accuracy : parseInt(record.form_values[constants.field_accuracy], 10)
    created  : record.created_at
    updated  : record.updated_at
  feature =
    type        : 'Feature'
    geometry    : geometry
    properties  : properties
  feature

processPayload = (payload) ->
  record = payloadToRecord payload
  checkLocationChanged record

payloadToRecord = (payload) ->
  coordinates = payload.location.split(',').map(parseFloat)
  record = {
    record: {
      latitude: coordinates[0]
      longitude: coordinates[1]
      form_id: constants.form_id
      form_values: {}
    }
  }

  record.record.form_values[constants.field_accuracy] = payload.location_accuracy
  record

createFulcrumRecord = (record_to_create) ->
  callback = (error, record) ->
    if error
      console.log "Error: #{error}"
    else
      console.log "Record created: #{record.record.id}"

  fulcrum.records.create record_to_create, callback

updateLastLocation = (record_to_update, accuracy) ->
  callback = (error, record) ->
    if error
      console.log "Error: #{error}"
    else
      console.log "Record updated: #{record.record.id}"

  record_to_update.form_values[constants.field_accuracy] = accuracy
  record_to_update =
    record: record_to_update
  fulcrum.records.update record_to_update.record.id, record_to_update, callback

checkLocationChanged = (new_location_record) ->
  callback = (error, records) ->
    if error
      console.log "Error: #{error}"
      return
    last_location_record = records.records[0]
    last_record_point    = point last_location_record.longitude, last_location_record.latitude
    new_location_point   = point new_location_record.record.longitude,  new_location_record.record.latitude

    distance_between = distance last_record_point, new_location_point, 'kilometers'
    if distance_between <= constants.minimum_location_change_distance
      console.log "Not creating a new record because distance from last location (#{distance_between} km) was less than the minimum distance recuired (#{constants.minimum_location_change_distance} km)."
      updateLastLocation last_location_record, new_location_record.record.form_values[constants.field_accuracy]
    else
      console.log "User moved. Creating a new record."
      createFulcrumRecord new_location_record

  search_options =
    form_id       : constants.form_id
    newest_first  : 1
    per_page      : 1
    page          : 1
  fulcrum.records.search search_options, callback
