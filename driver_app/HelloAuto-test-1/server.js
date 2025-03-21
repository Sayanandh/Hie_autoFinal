const http = require('http');
const app = require('./app');
const { initializeSocket } = require('./services/socket.service');

const port = process.env.PORT || 3000;

// Create the HTTP server
const server = http.createServer(app);

// Initialize socket.io with the server
initializeSocket(server);

server.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
