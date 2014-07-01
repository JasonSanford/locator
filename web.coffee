express = require 'express'
logfmt = require 'logfmt'

port = Number process.env.PORT or 5000

app = express()
app.use logfmt.requestLogger()
app.use(function(req, res, next) {
  req.rawBody = '';
  req.setEncoding('utf8');

  req.on('data', function(chunk) { 
    req.rawBody += chunk;
  });

  req.on('end', function() {
    next();
  });
});
app.use express.bodyParser()

app.get '/', (req, resp) ->
  resp.send 'You should POST to me.'

app.post '/', (req, resp) ->
  payload = req.rawBody
  processPayload payload
  resp.send 'Thanks. You\'re the best!'

app.listen port, ->
  console.log "Listening on port: #{port}"

processPayload = (payload) ->
  console.log "[payload]: #{JSON.stringify payload}"