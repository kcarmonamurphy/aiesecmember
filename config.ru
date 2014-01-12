require 'rubygems' 
require 'bundler'  

Bundler.require 

Rack::MethodOverride

require './platform.rb'

run Platform