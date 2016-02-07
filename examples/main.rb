$:.unshift File.expand_path '../lib', File.dirname(__FILE__)
require "debug_room"

debug_room = DebugRoom::Application.new
debug_room.run
