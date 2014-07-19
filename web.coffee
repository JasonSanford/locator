express = require 'express'
logfmt = require 'logfmt'
Fulcrum = require 'fulcrum-app'

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

fulcrum = new Fulcrum({api_key: constants.fulcrum_api_key})

processPayload = (payload) ->
  record = payloadToRecord payload
  createFulcrumRecord record

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

  record.record.form_values[constants.field_cell] = payload.cell
  record.record.form_values[constants.field_cell_signal_strength] = payload.cell_signal_strength
  record.record.form_values[constants.field_accuracy] = payload.location_accuracy

  record

createFulcrumRecord = (record_to_create) ->
  callback = (error, record) ->
    if error
      console.log "Error: #{error}"
    else
      console.log "Record created: #{record}"

  fulcrum.records.create record_to_create, callback
