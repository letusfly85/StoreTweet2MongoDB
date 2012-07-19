require './setup'
require './open_stream'
require './search_tweets'
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
                    :links   => [ { :title    => tweet['link_title'],
                                    :link     => tweet['link_url'],
                                    :imageUrl => tweet['image_url'] 
                                 }],
                },
            :apiKey => POSTREAM_API_KEY,
            }
    end

    def contain_ng_words?(text)
        nil
    end

    def text_check(tweet)
        nil
    end

    def post2postream
        include Utils
        include OpenStream
        include SearchTweets

        #POSTREAM_URI_NEW
        tweets_list = search_mongo

        tweets_list.each do |tweet_list|
            next if tweet_list['contents'] == nil

            tweet_list['contents'].each do |tweet|
                next if tweet["posted_count"] > 0

                post_message = {}
                
                next unless text_check(tweet)
                post_message = generate_post_contents(tweet)
            end
        end
    end

    def input_data2mongodb
        include OpenStream
        include Insert2MongoDB

        nil
    end

    def re_each(hash,i)
        tab = ""
        i.times {tab += "\t"}
        if hash.instance_of?(BSON::OrderedHash)
            i += 1
            hash.each do |k,v|
                next if k == 'user'
                if v.instance_of?(BSON::OrderedHash)
                    puts  "#{tab} #{k} : " 
                else
                    print "#{tab} #{k} : " 
                end
                re_each(v,i)
            end
        else
            puts "#{hash}" 
        end
        i += 1
    end

    def retweet_urls(value)
        value["retweeted_status"]["entities"]["urls"]
    end

    def slice_http_link_from_tweet_text(value)
        begin
            indices = []
            value["retweeted_status"]["entities"]["urls"].each do |url|
                indices << url["indices"]
            end

            pre_pos = 0
            whole_text = value["retweeted_status"]["text"]
            text = ""
            indices.each do |ind|
                start_pos = ind[0] - 1
                end_pos   = ind[1] + 1

                text += whole_text[pre_pos..start_pos]
                pre_pos = end_pos
            end
            text += whole_text[pre_pos..whole_text.length-1] unless pre_pos-1 == whole_text.length
        rescue => e
            puts whole_text
            puts value["id_str"]
            puts e
            raise
        end
        
        return text
    end

    def generate_post_contents(value)
        tweet = {}
        #re_each(value,1)
        #exit

        tweet["user_name"]  = value["retweeted_status"]["user"]["name"]
        tweet["text"]       = "#{ value["point"]} Pointの投稿です。>>=       " +
                              slice_http_link_from_tweet_text(value)

        begin
            expanded_urls = retweet_urls(value)
            tweet["link_url"] = expanded_urls[0]["expanded_url"]
        rescue 
            tweet["link_url"] = "Nothing"
        end

        tweet["link_title"] = get_html_title(tweet["link_url"]) rescue  tweet["link_title"] = "参照元URL"

        unless value['user']['profile_image_url_https'] == nil
            tweet["imageUrl"]   = value['user']['profile_image_url_https']
        end

        return tweet
    end
end
