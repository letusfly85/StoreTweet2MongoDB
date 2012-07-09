module Utils

    def recur_extend_uri(uri_name)
        if (/http\:\/\/bit/   =~ uri_name) or
           (/http\:\/\/t\.co/ =~ uri_name) or
           (/http\:\/\/dlvr/  =~ uri_name)
            extend_uri(uri_name)
        else
            uri_name
        end
    end

    def extend_uri(uri_name)
        uri = URI.parse(uri_name)
        http = Net::HTTP::Proxy(HTTP_PROXY_ADDR,HTTP_PROXY_PORT).new(uri.host, uri.port)
        res = http.request(Net::HTTP::Head.new uri.request_uri)
        return uri unless res['location']
        URI.parse res['location'] rescue return uri
    end

end


