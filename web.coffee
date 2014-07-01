express = require 'express'
logfmt = require 'logfmt'

port = Number process.env.PORT or 5000

app = express()
app.use logfmt.requestLogger()
app.use express.bodyParser()

app.post '/', (req, resp) ->
  payload = req.body
  processPayload payload
  resp.send 'Thanks. You\'re the best!'

app.listen port, ->
  console.log "Listening on port: #{port}"

processPayload = (payload) ->
  console.log "[payload]: #{JSON.stringify payload}"