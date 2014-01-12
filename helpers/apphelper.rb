require 'sinatra/base'
require 'securerandom'
require "sinatra/reloader" if development?

module Token
	def generate_token(column, length = 16)
		begin
			key = SecureRandom.urlsafe_base64 length 
		end while (Candidate.count(column => key) == 1)
		return key
	end
end

module Property
	def model_properties(model, start_property, stop_property)
		begin
			array = Array.new
			model.properties.each do |p|
				field = p.instance_variable_name.slice(1..-1).to_sym
				array.push(field)
			end
			start = array.index(start_property)
			stop = array.index(stop_property)
			return array.slice(start,stop)
		end
	end
end

module Inflector
	def humanize(str)
		return str.tr('_', ' ').split(" ").map(&:capitalize).join(" ")
	end
end

class Array
	def odd_values
	  self.values_at(* self.each_index.select {|i| i.odd?})
	end
	def even_values
	  self.values_at(* self.each_index.select {|i| i.even?})
	end
end
		
  

