require 'sinatra'
require 'haml'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'securerandom'
require 'rack-flash'  
require 'sinatra/redirect_with_flash'  
require './helpers/apphelper.rb'
require "sinatra/reloader" if development?

set :server, 'webrick'

DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db.db")
DataMapper::Model.raise_on_save_failure = false  

class Candidate
	include DataMapper::Resource
	property :id, Serial, :required => true
	property :full_name, String, :required => true,
	:messages => {
		:presence 	=> "Please provide your full name"
	}
	property :program_and_level, String, :required => true, 
    :messages => {
      	:presence 	 => "Please provide your program and level",
      	:format   	 => "Invalid email address"
    }
	property :birthdate, String, :required => true,
	:messages => {
		:presence 	=> "Please provide your birthdate"
	}
	property :student_number, String, :required => true, :length => 7,
	:messages => {
		:presence 	=> "Please provide your student number",
		:length		=> "Must be 7 digits"
	}
	property :mac_email, String, :required => true, :format => :email_address, :unique => true,
	:messages => {
		:presence 	 => "Please provide your mac email address",
      	:format   	 => "Invalid email address",
      	:is_unique	 => "Email already used"
	}
	property :alternate_email, String, :required => true, :format => :email_address, :unique => true,
	:messages => {
		:presence 	 => "Please provide an alternative email address",
      	:format   	 => "Invalid email address",
      	:is_unique	 => "Email already used"
	}
	property :phone_number, String, :required => true,
	:messages => {
		:presence 	=> "Please provide your phone number",
	}
	property :permanent_address, String, :required => true,
	:messages => {
		:presence 	=> "Please provide your permanent address"
	}
	property :current_address, String, :required => true,
	:messages => {
		:presence 	=> "Please provide your current address"
	}
	property :gender, String, :required => true

	property :q1, Text
	property :q2, Text
	property :q3, Text
	property :q4, Text
	property :q5, Text
	property :q6, Text
	property :q7, Text

	property :created_at, DateTime
	property :hex, String, :unique => true

end

DataMapper.finalize.auto_migrate!

class Platform < Sinatra::Base

	#helpers
	helpers Token
	helpers Sinatra::RedirectWithFlash
	helpers Property
	helpers Inflector

	configure :development do
    	register Sinatra::Reloader
    	also_reload './helpers/apphelper.rb'
  	end

  	enable :sessions
  	use Rack::Flash, :sweep => true  
  	#set :environment, :production

  	get '/' do
  		haml :index, :locals => {
	     	:action => "/create",
	     	:pagenum => "1",
	     	:fields => model_properties(Candidate, :full_name, :current_address)
   		}
	end

	post '/create' do 

		c = Candidate.new

		#save field parameters to record and session
		model_properties(Candidate, :full_name, :current_address).each do |field|
			c[field] = session[field] = params[field]
		end

		c[:gender] = session[:gender] = params[:gender]
		
		#additional special properties
		c.created_at = session[:created_at] = Time.now
		c.hex = generate_token(:hex, 4)

		#save record
   		if c.save
     		redirect "/#{c.hex}/pagetwo"
   		else
   			#error on save, show error messages
   			c.attributes.each do |a|
   				field = a.first
				flash[field] = c.errors.on(field) ? c.errors.on(field).first : nil
			end
     		redirect '/'
  		end

	end 

 	get '/:ca/pagetwo' do |ca|
  		c = Candidate.first(:hex => ca)
   		haml :pagetwo, :locals => {
			:c => c,
			:action => "/#{c.hex}/pagetwo/process",
			:pagenum => "2"
	 	}
	end

	post '/:ca/pagetwo/process' do |ca|
		c = Candidate.first(:hex => ca)

		# model_properties(Candidate, :q1, :q7).each do |field|
		# 	c[field] = params[field]
		# end

		c.birthdate = params[:birthdate]
		c.stud_number = params[:stud_number]

		c.save

		redirect "/#{c.hex}/pagethree"
	end

	get '/:ca/pagethree' do |ca|
		c = Candidate.first(:hex => ca)
		haml :pagethree, :locals => {
		    :c => c,
			:action => "/#{c.hex}/pagethree/process",
			:pagenum => "3"
	   	}
	end

	post '/:ca/pagethree/process' do |ca|
		c = Candidate.first(:hex => ca)

		c.phone_num = params[:phone_num]
		c.perm_address = params[:perm_address]

		c.save

		redirect "/#{c.hex}/complete"
	end

	get '/:ca/complete' do |ca|
		c = Candidate.first(:hex => ca)
		haml :complete, :locals => {
		    :c => c,
			:action => "/admin"
	   	}
	end

	get '/admin' do
		haml :admin, :locals => { :candidates => Candidate.all}
	end

	not_found do  
  		halt 404, 'page not found'  
	end  

end