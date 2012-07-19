require './open_stream'
require './insert2mongodb'
require './post2postream'

include OpenStream
include Insert2MongoDB
include Post2Postream

twitter_stream(USER_STREAM,{})
exit
exit if json_ary.length == 0

json_ary.each_with_index do |col,idx|
    next    if idx == 0 or col['text'] == nil
    next    if col.has_key?("friends")
    re_each(col,0)
    insert2database($val_key[USER_STREAM].downcase,json)
    tweet = {}
    tweet["text"]       = col["text"]

    next if col['entities'] == nil
    tweet["link_url"]   = col['entities']['urls'][0]["expanded_url"]
    tweet["link_title"] = tweet["text"][0..200]
    puts tweet

    uri_str = "https://#{POSTREAM_SERVER_HOST}:#{POSTREAM_SERVER_PORT}/api/streams/posts/new"
end
