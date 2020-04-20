vcl 4.0;
import std;
import vsthrottle;
import var;

# Config inspired from https://www.fastly.com/blog/server-sent-events-fastly

backend default {

    # Set a host.
    .host = "eventvarnish";

    # Set a port. 80 is normal Web traffic.
    .port = "80";
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

    /* if(var.global_get("url") ~ "/stream") {
        set req.http.Range = "bytes=12";
    } */

    # decrements the token
    if(vsthrottle.is_denied(client.identity, 30, 60s)) {
        # Client has more than 3 requests per min
        return (synth(429, "Too Many Requests In Flight"));
    }
}

sub vcl_deliver {

    set resp.http.X-RateLimit-Remaining = vsthrottle.remaining(client.identity, 30, 60s);
    
    if(obj.hits > 0) {
        set resp.http.X-Varnish-Cache = "HIT";
    } else {
        set resp.http.X-Varnish-Cache = "MISS";
    }

    var.global_set("url", req.url);

    set resp.http.X-Current-Url = var.global_get("url");

    return(deliver);
}