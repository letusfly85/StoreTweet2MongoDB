require './open_stream'

include OpenStream
twitter_stream(FILTER_STREAM,{"keywords" => ['job','haskell','change']})

