require './setup'

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
        # http用のコネクションを取得する
        # プロキシがプロパティファイルに記載されていれば利用する
        if HTTP_PROXY_ADDR.nil? or HTTP_PROXY_ADDR.length == ZERO
            connection = Net::HTTP.new(host,port)
        else
            connection = Net::HTTP::Proxy(HTTP_PROXY_ADDR,HTTP_PROXY_PORT).
                                 new(host,port)
        end

        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE

        return connection
    end

    def twitter_stream(stream_name,key_hash)
        generate_keys
        stream_uri = URI::parse(stream_name)

        unless key_hash["keywords"].nil?
            key_list = array2key_list(key_hash["keywords"])

            req = Net::HTTP::Post.new(stream_uri.request_uri)
            req.set_form_data('track' => key_list)
        else
            req = Net::HTTP::Get.new(stream_uri.request_uri)
        end

        connection = http_connection(stream_uri.host,stream_uri.port)

        json_ary = []
        connection.start do |http|
            req.oauth!(http,@consumer,@access_token)

            http.request(req) do |response|
                raise 'Response is not chuncked' unless response.chunked?
                response.read_body do |chunk|
                    status = JSON.parse(chunk) rescue next
                    
                    next unless status['text']
                    if key_hash["return_flg"] == "once"
                    	exit
                    elsif key_hash["return_flg"] == "hash"
                        @countup += 1
                        json_ary << status
                        if @countup >= 10
                            return json_ary
                        end
		    else
                        puts status
                        exit
                    end
                end
            end
        end
    end

    def array2key_list(array)
        key_list = ""
        array.each do |key|
            key_list += key + ","
        end

        return key_list
    end

    attr_accessor :consumer,:access_token,:countup
end
