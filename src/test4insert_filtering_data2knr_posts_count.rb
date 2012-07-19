require './setup'
require './insert2mongodb'

include Insert2MongoDB

connect

tweets = @db[$val_key[USER_STREAM].downcase].find()

tweets.each do |tweet|
    unless tweet.key?("friends")
        register_knr_posts_count(tweet)
    end
end
