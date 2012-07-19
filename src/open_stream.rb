#TODO stop to use a relative path
require './setup'
require './insert2mongodb'

module OpenStream
    def generate_keys
        @consumer = OAuth::Consumer.new(
            TWITTER_CONSUMER_KEY,
            TWITTER_CONSUMER_SECRET,
            :site => TWITTER_SITE_NAME
        )

        @access_token = OAuth::AccessToken.new(
            @consumer,
            TWITTER_OAUTH_TOKEN,
            TWITTER_OAUTH_TOKEN_SECRET
        )

        @countup = ZERO
    end

    def http_connection(host,port)
        if HTTP_PROXY_ADDR.nil? or HTTP_PROXY_ADDR.length == ZERO
            connection = Net::HTTP.new(host,port)
        else
            connection = Net::HTTP::Proxy(HTTP_PROXY_ADDR,HTTP_PROXY_PORT).
                                 new(host,port)
        end

        #TODO check the meanings of Net::HTTP's options such like below 
        connection.use_ssl      = true
        connection.verify_mode  = OpenSSL::SSL::VERIFY_NONE
        connection.read_timeout = MAX_READ_TIMEOUT

        return connection
    end

    def twitter_stream(stream_name,options)
        generate_keys
        stream_uri = URI::parse(stream_name)

        if stream_name == FILTER_STREAM
            key_list = array2key_list(options[:post_parameters])

            req = Net::HTTP::Post.new(stream_uri.request_uri)
            req.set_form_data(:track => key_list)
        #elsif stream_name == USER_STREAM
        #    req = Net::HTTP::Post.new(stream_uri.request_uri)
        #    req.set_form_data(:follow => "topitmedia,")
        else
            req = Net::HTTP::Get.new(stream_uri.request_uri)
        end

        connection = http_connection(stream_uri.host,stream_uri.port)

        json_ary = []
        begin
            connection.start do |http|
                req.oauth!(http,@consumer,@access_token)

                http.request(req) do |response|
                    raise 'Response is not chuncked' unless response.chunked?

                    response.read_body do |chunk|
                        buf = ""
                        buf << chunk

                        # 改行コードで区切って一行ずつ読み込み
                        while (line = buf[/.+?(\r\n)+/m]) != nil 
                            begin
                                # 読み込み済みの行を削除
                                buf.sub!(line,"") 
                                line.strip!
                                status = JSON.parse(line)
                                puts status
                                insert2database($val_key[USER_STREAM].downcase,status)

                                #json_ary << status
                                #sleep(1)
                                #@countup += 1
                                #return json_ary if @countup >= TWEETS_ARRAY_MAX_SIZE
                            rescue
                                # parseに失敗したら、次のループでchunkをもう1個読み込む
                                break 
                            end
                            if status['text']
                                user = status['user']
                                puts "#{user['screen_name']}: #{CGI.unescapeHTML(status['text'])}"
                            end
                        end

#                        status = nil
#                        begin
#                            status = JSON.parse(chunk)
#                            puts status
#                        rescue =>e
#                            puts e
#                            next
#                        end
#
#                        next unless status['text'] 
#
#                        #my_hash = { :id => status['id'], :text => status['text'] }
#                        #json_ary << my_hash
#                        json_ary << status
                        
#                        sleep(1)
#                        @countup += 1
#                        return json_ary if @countup >= TWEETS_ARRAY_MAX_SIZE
                    end
                end
            end

        ensure
            connection = nil
        end
    end

    def array2key_list(array)
        key_list = ""
        array.each {|key| key_list += key + ","}

        return key_list
    end

    attr_accessor :consumer,:access_token,:countup
end
