module WeightingTweet
    def weighting_tweet(tweet_user_name,retweet_count,diff_time)
        user_point  = mongo_user_weight(tweet_user_name)
        fresh_point = calc_fresh(diff_time)

        weight_point = user_point * retweet_count * fresh_point
    end

    def mongo_user_weight(tweet_user_name)
        include SearchTweets
        user_weight(tweet_user_name)
    end

    def fresh_point(diff_time)
        100
    end
end
