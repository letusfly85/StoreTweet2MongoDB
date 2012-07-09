#require 'net/http'
#require 'kconv'
#require './setup'

module Utils

    def recur_extend_uri(uri_name)
        return uri_name if (/\.html/) =~ uri_name
        if (/http\:\/\/bit\./   =~ uri_name) or
           (/http\:\/\/t\.co/   =~ uri_name)
         #  (/http\:\/\/ow\.ly/  =~ uri_name) or
         #  (/http\:\/\/htn\./   =~ uri_name) or
         #  (/http\:\/\/dlvr/    =~ uri_name)
            expand_url(uri_name)
        else
            uri_name
        end
    end

    def expand_url(url)
        uri = url.kind_of?(URI) ? url : URI.parse(url);
        Net::HTTP::Proxy(HTTP_PROXY_ADDR,HTTP_PROXY_PORT).start(uri.host, uri.port) do |io|
            r = io.head(uri.path);
            URI.parse(r['Location']||uri.to_s).scheme ?
                     ((r['Location']||uri.to_s) == url ?
                      url : expand_url(r['Location']||uri.to_s)) : url;
        end
    end

    def get_html_title(uri)
        title = Net::HTTP::Proxy(HTTP_PROXY_ADDR,HTTP_PROXY_PORT).get_response(URI.parse(uri)).body.tosjis.scan(/<title>(.*)<\/title>/i)[0][0]
        return title
    end
end

#include Utils
#my_uri    = recur_extend_uri('http://t.co/XxwjqNQm')
#puts my_uri

#my_title  = get_html_title(my_uri)
#puts my_title.length
#puts my_title
