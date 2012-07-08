#TODO stop to use a relative path
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
        if HTTP_PROXY_ADDR.nil? or HTTP_PROXY_ADDR.length == ZERO
            connection = Net::HTTP.new(host,port)
        else
            connection = Net::HTTP::Proxy(HTTP_PROXY_ADDR,HTTP_PROXY_PORT).
                                 new(host,port)
        end

        #TODO check the meanings of Net::HTTP's options such like below 
        connection.use_ssl = true
        connection.verify_mode = OpenSSL::SSL::VERIFY_NONE

        return connection
    end

    def twitter_stream(stream_name,options)
        generate_keys
        stream_uri = URI::parse(stream_name)

        if stream_name == FILTER_STREAM
            key_list = array2key_list(options[:post_parameters])

            req = Net::HTTP::Post.new(stream_uri.request_uri)
            req.set_form_data(:track => key_list)
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

                    @countup += 1
                    json_ary << status
                    return json_ary if @countup >= TWEETS_ARRAY_MAX_SIZE
                end
            end
        end
    end

    def array2key_list(array)
        key_list = ""
        array.each {|key| key_list += key + ","}

        return key_list
    end

    attr_accessor :consumer,:access_token,:countup
end
