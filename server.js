const express = require('express');
const SSEChannel = require('sse-pubsub');

const app = express();
const channel = new SSEChannel();

let count = 1;
// Say hello every second
setInterval(() => {
    channel.publish("Hello all "+channel.getSubscriberCount()+" clients out there! "+count+' => '+Date.now().toString(), 'myEvent');
    count++;
}, 5000);

app.get('/stream', (req, res) => channel.subscribe(req, res));

app.get('/std', (req, res) => {
    res.header('X-Custom-TTL', '30');
    res.write('this is standard answer '+Date.now().toString());
    res.end();
});

app.listen(8080);