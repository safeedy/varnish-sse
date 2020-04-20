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
# 0 - make sure compression is disabled by origin
# 1 - enable request collapsing by setting grace => only 1 request will be sent to origin, all other clients wait for it to be dispatched
# 2 - enable do_stream for text/event-stream
# 3 - time to live must be equal to max stream duration from origin => prevent from potential timeout in middle servers/proxies
sub vcl_backend_response {
    if (bereq.url ~ "/stream") {
        if(var.global_get("stream_start") != "1") {
            # [a]: MISS - set ttl
            set beresp.grace = 0s;
            set beresp.ttl = 29s;
            set beresp.http.X-Grace-Set-Leaf = "YES";
        }
        if(beresp.http.X-Varnish-Cache-Top == "HIT" && var.global_get("stream_start") == "0") {
            # expire TTL to provoke a MISS and start over to [a]
            set beresp.ttl = 1s;
            var.global_set("stream_start", "0");
            set beresp.http.X-Grace-Set-Leaf = "NO";
        }
        set beresp.http.Cache-Control = "public, max-age=0";
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
    var.global_set("stream_start", "0");

    # decrements the token
    if(vsthrottle.is_denied(client.identity, 30, 60s)) {
        # Client has more than 3 requests per min
        return (synth(429, "Too Many Requests In Flight"));
    }
}

sub vcl_deliver {

    set resp.http.X-RateLimit-Remaining = vsthrottle.remaining(client.identity, 30, 60s);
    
    if(obj.hits > 0) {
        set resp.http.X-Varnish-Cache-Leaf = "HIT";
        if(resp.http.X-Varnish-Cache-Top == "HIT") {
            var.global_set("stream_start", "0");
        }
    } else {
        set resp.http.X-Varnish-Cache-Leaf = "MISS";
    }

    var.global_set("url", req.url);

    set resp.http.X-Current-Url = var.global_get("url");
    set resp.http.X-Stream-Start = obj.ttl+":"+var.global_get("stream_start");

    return(deliver);
}