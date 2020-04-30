const express = require('express');
const fs = require('fs');
const SSEChannel = require('./SSEChannel');

const app = express();
// max number of served clients = maxStreamDuration / cacheDuration
const channel = new SSEChannel({maxStreamDuration: 30000, pingInterval: 0, clientRetryInterval: 5});

let count = 1;
// Say hello every second
setInterval(() => {
    channel.publish("nb "+channel.getSubscriberCount()+" clients! "+count+' => '+Date.now().toString(), 'myEvent');
    count++;
}, 1000);

app.get('/stream', (req, res) => {
    channel.subscribe(req, res);
    //channel.resetMetrics();
});

app.get('/std', (req, res) => {
    res.header('X-Custom-TTL', '30');
    res.write('this is standard answer '+Date.now().toString());
    res.end();
});

app.get('/file', (req, res) => {
    res.header('X-Custom-TTL', '30');
    fs.readFile('content.json', (err, data) => {
        res.write(data);
        res.end();
    })
});

app.listen(8080);