# varnish-sse

Build varnish image with :

    docker build -t ubuntu-varnish:1.0 .

Start Project with :

    docker-compose up -d

NPM dependencies will be installed
Node server will be launched
    
Run direct queries in 3 tabs at **localhost:3000/stream** => 3 clients counted will be connected

In **varnishleaf** container exposing port 80 : Run queries in 3 tabs through varnish cache & request collapsing with at **localhost/stream** => only **1 client count**

In **varnishleaf1** container : Do

    docker exec -ti varnishleaf1 bash
    curl localhost/stream
    
Run curl n times => still **one client count**
 
 
