# varnish-sse

Start Project with :

    docker-compose up -d
    
Start server with :

    docker exec -ti eventnode bash
    > node server.js
    
Run direct queries in 3 tabs at **localhost/stream** => 3 clients counted will be connected

Run queries in 3 tabs through varnish cache & request collapsing with at **localhost:8080/stream** => only 1 client count
 
 
