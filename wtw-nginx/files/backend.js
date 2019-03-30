const http = require('http')
const port = 3400

const requestHandler = (request, response) => {
  console.log(request.url)
  response.end('Hello! Welcome to www.example.com!\n')
}

const server = http.createServer(requestHandler)

server.listen(port, '127.0.0.1', (err) => {
  if (err) {
    return console.log('something bad happened', err)
  }

  console.log(`server is listening on ${port}`)
})
