require 'rubygems'
require 'mongo'
require 'net/http'
require './setup'

# bit系にのみ対応
def expand_bit_url(bit_url)
    return unless /http\:\/\/bit/ =~ expanded_url

    url = URI.parse(bit_url)
    http = Net::HTTP::Proxy(HTTP_PROXY_ADDR,HTTP_PROXY_PORT).start(url.host,url.port)
    res = http.get(url.path)

    if (res.code == "200")
        return nil
    elsif (res.code == "301")
        return res["location"]
    end
end

@con = Mongo::Connection.new(MONGO_HOST_NAME,MONGO_HOST_PORT)
@db  = @con.db(MONGO_DB_NAME)

counter = 0
@db[MONGO_USER_STREAM].find({"retweeted_status.entities.urls" => {"$exists" => true}}).each do |col|
    col["retweeted_status"]["entities"]["urls"].each do |url|
        next unless url.has_key?("expanded_url")

        expanded_url = url["expanded_url"]
        counter += 1 if /html$/ =~ expanded_url

        res = expand_bit_url(expanded_url)
        next if res == nil
        counter += 1 unless  /html/ =~ res
    end
end

@db[MONGO_USER_STREAM].find({"entities.urls" => {"$exists" => true}}).each do |col|
    col["entities"]["urls"].each do |url|
        next unless url.has_key?("expanded_url")

        expanded_url = url["expanded_url"]
        counter += 1 if /html$/ =~ expanded_url

        res = expand_bit_url(expanded_url)
        next if res == nil
        counter += 1 unless  /html/ =~ res
    end
end

puts counter
