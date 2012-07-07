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

    attr_accessor :db
end
