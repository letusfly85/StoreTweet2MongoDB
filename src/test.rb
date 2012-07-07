require './open_stream'
require './insert2mongodb'

include OpenStream
include Insert2MongoDB

json_ary = twitter_stream(SAMPLE_STREAM,{"return_flg" => 'hash' })
json_ary.each {|json| insert2database($val_key[SAMPLE_STREAM].downcase,json)}

json_ary = twitter_stream(FILTER_STREAM,
			   { "keywords"    => ['job','haskell','change'],
				  "return_flg" => 'hash' }
			  )

json_ary.each {|json| insert2database($val_key[FILTER_STREAM].downcase,json)}
