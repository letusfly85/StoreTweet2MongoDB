require './setup'
require './open_stream'
require './utils'

module Post2Postream

    def https_post(uri_str, msg)
        msg_json = msg.to_json
        header = {
            'X-Kodama'       => 'Request/API',
            'Content-Type'   => 'application/json',
            'Connection'     => 'close',
            'Content-Length' => msg_json.bytesize.to_s
        }

        #TODO decide which I use Faraday or not
        uri = URI(uri_str)
        unless HTTP_PROXY_ADDR == nil or HTTP_PROXY_ADDR.length == ZERO
            conn = Faraday.new("https://#{uri.host}",
                                :ssl => {:verify => false, :timeout => 20, :open_timeout => 20},
                                :proxy => URI.parse("http://#{HTTP_PROXY_ADDR}:#{HTTP_PROXY_PORT}"))
        else
            conn = Faraday.new("https://#{uri.host}",
                                :ssl => {:verify => false, :timeout => 20, :open_timeout => 20})
        end

        begin
            res = conn.post do |req|
                req.url uri.path
                req.headers = header
                req.body = msg_json
            end
        rescue Faraday::Error::TimeoutError => e
            puts "....Timeout...."
            puts e
        end
    end

    def post_body(uri,tweet)
        body = {
            :post => {
                :content => tweet['text'],
                :links   => [ { :title => tweet['link_title'],
                                :link  => tweet['link_url']   } ],
        },
        :apiKey => POSTREAM_API_KEY,
        }
    end

    def contain_ng_words?(text)
        #TODO consider in where words list should be.
        ng_word_list = ['ねとらぼ']
        ng_word_list.each do |ng_word|
            /"#{ng_word}"/ =~ text
            return true
        end
        return false
    end

    #TODO decide from where input data should be pulled
    def post2postream
        include OpenStream
        include Utils

        #TODO consider in where post parameters should be
        json_ary = twitter_stream(FILTER_STREAM,
                                   { :post_parameters => 
                                       ['ITmedia','AndroidNewsJP',
                                       'itmedia_m','itmedia','haskell','ocalm',
                                       'http://news.livedoor.com/category/list/25/'] },
                                 )

        uri_str = "https://#{POSTREAM_SERVER_HOST}:#{POSTREAM_SERVER_PORT}/api/streams/posts/new"
        json_ary.each do |json|
            tweet = {}
            http_link = json["text"].scan(/http\:\/\/[\w.\/]*/)[0] rescue http_link = nil
            contents  = json["text"].delete(http_link) unless http_link == nil

            tweet["text"]       = contents

            unless http_link == nil
                tweet["link_url"]   = recur_extend_uri(json["text"].scan(/http\:\/\/[\w.\/]*/)[0])
                tweet["link_title"] = get_html_title(tweet["link_url"])
            end

            unless contain_ng_words?(tweet["text"])
                #https_post(uri_str, post_body(uri_str, tweet))
                #display(json,tweet)
                nil
            end
        end
    end

    def input_data2mongodb
        include OpenStream
        include Insert2MongoDB

        nil
    end

    #TODO if it become to be needless, delete this function
    def display(json,tweet)
            puts "#{json["id"]} : #{json["created_at"]}"
            puts " => http_link        : #{tweet["link_url"]}"
            puts " => http_link_title  : #{tweet["link_title"]}"
            puts " => contents         : #{tweet["text"]}\n"
    end

end


include Post2Postream
begin
    inputs_mongo
rescue => error
    case  error
    when EOFError
        puts '......EOFError.....'
        puts error
        inputs_mongo
    else
        puts '......OTHER..ERROR.....'
        puts '......The authour should add a new error pattern....'
        puts error
    end
end
