$:.unshift File.expand_path '../lib', File.dirname(__FILE__)
require "debug_room"

# 何らかの処理...
sleep 3

client = DebugRoom::Client.new
client.send_message("終わったよ")
