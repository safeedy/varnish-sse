const express = require('express');
const fs = require('fs');
const io = require('socket.io');

const content = require('./content.json');

const app = express();

app.get('/', (req, res) => {
    res.header('X-Custom-TTL', '30');
    res.write(`
    <html>
    <body>
        <h3>This is standard answer</h3>
        <script type="text/javascript" src="/socket.io/socket.io.js"></script>
        <script>
        var socket = io();
        socket.on('placeholder', function(msg){
            console.log(msg);
        });
        </script>
    </body>
    </html>
    `);
    res.end();
});

const listener = app.listen(8080, function() {
	console.log('Listening on port ' + listener.address().port);
});

let clients = 0;
let id = 0;

const sockets = io().listen(listener, {pingInterval: 120000,
    pingTimeout: 5000});

sockets.on('connection', socket => {
	clients++;
	/*console.log(
		'Get a connection from: ',
		socket.handshake.headers['x-forwarded-for'] ||
			socket.handshake.address.address
    );*/
    socket.write('welcome');
	//console.log('Clients: ', clients);

	socket.on('disconnect', () => {
		clients--;
		//console.log('Clients: ', clients);
	});
});

setInterval(() => {
	console.log('Message send: ', ++id, 'to clients: ', clients);
	sockets.emit('placeholder', { id, data: content });
}, 1000);
