require 'rubygems'
require 'mongo'

module SearchTweets

    def connect
        @con = Mongo::Connection.new(MONGO_HOST_NAME,MONGO_HOST_PORT)
        @db  = @con.db(MONGO_DB_NAME)
    end

    def get_keywords
        key_words = []

        file = File.open("keywords","r")
        file.each {|line| key_words << line.chomp}
        file.close

        return key_words
    end

    def search_mongo
        connect
        key_words = get_keywords
        tweets_list = [{}]

        key_words.each do |key_word|
            tweet_list = {}
            tweet_list['key_word'] = key_word

            tweets = @db[MONGO_KNR_POSTS_COUNT.downcase].
                find(
                        { "posted_count" => ZERO,
                          "text"         => /#{key_word.chomp}/
                        # '$or' => [ {'text' => /#{key_word}/},{ 'text' => /ƒVƒXƒeƒ€/ } ] #EXAMPLE
                        }
                    )

            tweet_ary = []
            tweets.each do |tweet|
                tweet_ary << tweet
            end

            tweet_list['contents'] = tweet_ary
            tweets_list << tweet_list unless tweet_ary.length == ZERO
        end

        return tweets_list
    end

    def user_weight(tweet_user_name)
        100
    end

    attr_accessor :con, :db
end
