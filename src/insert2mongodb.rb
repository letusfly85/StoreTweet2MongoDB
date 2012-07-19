require 'rubygems'
require 'mongo'

module Insert2MongoDB
    def connect
        @con = Mongo::Connection.new(MONGO_HOST_NAME,MONGO_HOST_PORT)
        @db  = @con.db(MONGO_DB_NAME)
    end

    def insert2database(stream_name,hash)
        begin
            connect
            @db[stream_name].insert(hash)

        rescue => e
            puts 'you enter to the ERROR scope!'
            puts e
        ensure
            @con.close
        end
    end

    def register_knr_posts_count(hash)
        # リツィートされていなければパスする。
        return unless hash.has_key?("retweeted_status")

        # リツィート数が0であればパスする。
        return if hash["retweet_count"] == ZERO

        # entities:urlsがなければパスする。
        return unless hash.has_key?("entities")
        return unless hash["retweeted_status"]["entities"].has_key?("urls")
        return if     hash["retweeted_status"]["entities"]["urls"] == nil
        return if     hash["retweeted_status"]["entities"]["urls"].length == ZERO
        puts hash

        uri_str = "https://#{POSTREAM_SERVER_HOST}:#{POSTREAM_SERVER_PORT}/api/streams/posts/new"
        begin
            connect
            
            #TODO 登録済である場合は、posted_countを１インクリメントする。
            #TODO mod(posted_count,30) == 0の場合は再ポストする
            #TODO 登録済出ない場合は、posted_countを１に設定して1ポスト実行

            # hash['id_str']登録済みで存在確認
            res = @db[MONGO_KNR_POSTS_COUNT].find( {'id_str' => hash["id_str"] } )

            if  res.count != ZERO or res.count%30 != ZERO
                post = {}
                res.each {|x| post = x}
                nil
                #@db[MONGO_KNR_POSTS_COUNT].update( {'posted_count' => res[0]['posted_count'] + 1} )

            elsif (res.count%30) == ZERO and res.count != ZERO
                #@db[MONGO_KNR_POSTS_COUNT].update( {'posted_count' => res[0]['posted_count'] + 1} )

            else
                @db[MONGO_KNR_POSTS_COUNT].insert( hash.merge!({'posted_count' => 0}) )
                @db[$val_key[USER_STREAM].downcase].remove( {"id_str" => hash["id_str"] })
            end
        
        ensure
            @con.close
        end
    end

    attr_accessor :db,:con
end
