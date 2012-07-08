require './open_stream'
require './insert2mongodb'

include OpenStream
include Insert2MongoDB

#TODO consider how it should be about options(hash).
#     It's not good like below.
json_ary = twitter_stream(SAMPLE_STREAM,{})
json_ary.each {|json| insert2database($val_key[SAMPLE_STREAM].downcase,json)}

json_ary = twitter_stream(FILTER_STREAM,
			   { :post_parameters => ['job','haskell','change'] }
                         )

json_ary.each {|json| insert2database($val_key[FILTER_STREAM].downcase,json)}
