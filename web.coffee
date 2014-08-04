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

app.get '/', (req, resp) ->
  resp.send 'You should POST to me.'

app.post '/', (req, resp) ->
  payload = req.body
  processPayload payload
  resp.send 'Thanks. You\'re the best!'

app.listen port, ->
  console.log "Listening on port: #{port}"

fulcrum = new Fulcrum({api_key: api_key})

processPayload = (payload) ->
  record = payloadToRecord payload
  checkLocationChanged record
  updateLastLocation record

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

updateLastLocation = (record_to_update) ->
  callback = (error, record) ->
    if error
      console.log "Error: #{error}"
    else
      console.log "Record updated: #{record.record.id}"

  fulcrum.records.update constants.last_location_record_id, record_to_update, callback

checkLocationChanged = (new_location_record) ->
  callback = (error, last_location_record) ->
    if error
      console.log "Error: #{error}"
      return
    last_record_point  = point last_location_record.record.longitude, last_location_record.record.latitude
    new_location_point = point new_location_record.record.longitude,  new_location_record.record.latitude

    distance_between = distance last_record_point, new_location_point, 'kilometers'
    if distance_between <= constants.minimum_location_change_distance
      console.log "Not creating a new record because distance form last location (#{distance_between}) was less than the minimum distance (#{constants.minimum_location_change_distance})."
    else
      console.log "User moved. Creating a new record."
      createFulcrumRecord new_location_record

  fulcrum.records.find constants.last_location_record_id, callback
