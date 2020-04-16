vcl 4.0;
import std;

# Config inspired from https://www.fastly.com/blog/server-sent-events-fastly

backend default {

    # Set a host.
    .host = "eventnode";

    # Set a port. 80 is normal Web traffic.
    .port = "8080";
}

# important for event streams
# 1 - enable request collapsing by setting grace => only 1 request will be sent to origin, all other clients wait for it to be dispatched
# 2 - enable do_stream for text/event-stream
# 3 - time to live must be equal to max stream duration from origin => prevent from potential timeout in middle servers/proxies
sub vcl_backend_response {
    if (bereq.url ~ "/stream") {
        set beresp.grace = 30s;
        set beresp.keep = 30s;
        set beresp.ttl = 30s;
        set beresp.http.X-Grace-Set = "YES";
        set beresp.http.Cache-Control = "public, max-age=29";
    }
    else {
        set beresp.ttl = std.duration(beresp.http.X-Custom-TTL + "s", 10s);
    }

    if (beresp.http.Content-Type ~ "^text/event-stream") {
        set beresp.do_stream = true;
        set beresp.http.X-Stream-Type = "Event stream";
    }
}

# Varnish will not cache if a cookie is set
sub vcl_recv {
    unset req.http.Cookie;
}

sub vcl_deliver {
    
    if(obj.hits > 0) {
        set resp.http.X-Varnish-Cache = "HIT";
    } else {
        set resp.http.X-Varnish-Cache = "MISS";
    }

    return(deliver);
}