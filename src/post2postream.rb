require './setup'
require './open_stream'
require './utils'

def https_post(uri_str, msg)
    msg_json = msg.to_json

    header = {
      'X-Kodama'       => 'Request/API',
      'Content-Type'   => 'application/json',
      'Connection'     => 'close',
      'Content-Length' => msg_json.bytesize.to_s
    }

    puts uri_str
    puts msg_json.bytesize

    uri = URI(uri_str)
    conn = Faraday.new("https://#{uri.host}",
        :ssl => {:verify => false, :timeout => 20, :open_timeout => 20},
        :proxy => URI.parse("http://#{HTTP_PROXY_ADDR}:#{HTTP_PROXY_PORT}"))

    begin
      res = conn.post do |req|
        req.url uri.path
        req.headers = header
        req.body = msg_json
      end
    rescue Faraday::Error::TimeoutError=>e
      puts "....Timeout...."
      puts e
    end
end

def post_body(uri,tweet)
    body = {
      'post' => {
        :content => tweet['text'],
        :links   => [{:title => tweet['link_title'], :link => tweet['link_url']}],
      },
      'apiKey' => POSTREAM_API_KEY,
    }
end

def contain_ng_words?(text)
    word_list = ['ねとらぼ']
    puts text
    word_list.each do |word|
        /"#{word}"/ =~ word
        return true
    end
    return false
end

include OpenStream

begin
    def inputs_mongo
        include Utils

        uri_str = "https://#{POSTREAM_SERVER_HOST}:#{POSTREAM_SERVER_PORT}/api/streams/posts/new"

        json_ary = twitter_stream(FILTER_STREAM,
                                   { :post_parameters => ['ITmedia','AndroidNewsJP',
                                       'itmedia_m','itmedia','haskell','ocalm',
                                        'http://news.livedoor.com/category/list/25/'] },
                                 )
        json_ary.each do |j|
            tweet = {}
            http_link = j['text'].scan(/http\:\/\/[\w.\/]*/)[0]
            puts j['text']
            contents  = j['text'].delete(http_link)

            tweet['text'] = contents
            tweet['link_url']   = recur_extend_uri(j['text'].scan(/http\:\/\/[\w.\/]*/)[0])
            tweet['link_title'] = get_html_title(tweet['link_url'])

            puts "======================================="
            puts "#{j['id']} : #{j['created_at']}"
            puts " => http_link_       : #{http_link}"
            puts " => http_link        : #{tweet['link_url']}"
            puts " => http_link_title  : #{tweet['link_title']}"
            puts " => contents         : #{contents}\n\n"
            #sleep(3)
            unless contain_ng_words?(tweet['text'])
            #https_post(uri_str, post_body(uri_str, tweet))
                nil
            end
            #exit
            
        end
    end

    inputs_mongo
    exit

rescue => e
    case e
    when EOFError
        puts 'error!'
        puts e
        inputs_mongo
    else
        puts 'other error'
        puts e
    end
end
