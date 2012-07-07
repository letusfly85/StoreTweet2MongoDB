require './open_stream'

include OpenStream
#twitter_stream(SAMPLE_STREAM,{})
json_ary = twitter_stream(FILTER_STREAM,
			   {"keywords" => ['job','haskell','change'],
				"return_flg" => 'hash' }
			  )

include Insert2MongoDB
json_ary.each {|json| insert2database($val_key[FILTER_STREAM].downcase,json)}
