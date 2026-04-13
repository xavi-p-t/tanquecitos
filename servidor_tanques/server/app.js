const http = require('http');

const WebSockets = require('./utilsWebSockets.js');
const GameMessages = require('./utilsGameMessages.js');
const GameLoop = require('./utilsGameLoop.js');

// Configuración básica
const port = 3000;
const ws = new WebSockets();
const gameMessages = new GameMessages(ws);
const gameLoop = new GameLoop();


const httpServer = http.createServer();


ws.init(httpServer, port);

ws.onConnection = (socket, id) => {
    console.log(`Cliente conectado: ${id}`);
    gameMessages.addClient(id);
};

ws.onMessage = (socket, id, msg) => {
   
    console.log(`Mensaje recibido de ${id}: ${msg}`);
};

ws.onClose = (socket, id) => {
    console.log(`Cliente desconectado: ${id}`);
    gameMessages.removeClient(id);
};


gameLoop.run = (fps) => {
    gameMessages.flushAll();
};


httpServer.listen(port, () => {
    console.log(`Servidor de conexión base en: http://localhost:${port}`);
    gameLoop.start();
});