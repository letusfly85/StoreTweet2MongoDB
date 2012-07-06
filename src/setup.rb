require 'rubygems'
require 'uri'
require 'net/http'
require 'oauth'
require 'json'
require 'inifile'

ROUTE_PATH=Dir::pwd
PROPERTY_FILE_NAME='.property'

# .property ‚©‚çİ’èî•ñ‚ğƒ[ƒh‚µ’è”‰»
ini_file = IniFile.load("#{ROUTE_PATH}\/#{PROPERTY_FILE_NAME}")
$val_key = {}
ini_file.each do | section, key |
    eval("#{key} = #{ini_file[section][key]}")
    eval("\$val_key[\"#{ini_file[section][key]}\"] = key")
    puts $val_key["#{ini_file[section][key]}"]
end

$val_key.each do |k,v|
    puts k
    puts v
end
