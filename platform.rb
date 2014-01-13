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
DataMapper::Property.accept_options(:field_title)

class Candidate
	include DataMapper::Resource

	property :id, Serial, :required => true
	property :full_name, String, :required => true, :field_title => "Full Name",
	:messages => {
		:presence 	=> "Please provide your full name"
	}
	property :program_and_level, String, :required => true, :field_title => "Program & Level",
    :messages => {
      	:presence 	 => "Please provide your program and level",
      	:format   	 => "Invalid email address"
    }
	property :birthdate, String, :required => true, :field_title => "Birthdate",
	:messages => {
		:presence 	=> "Please provide your birthdate"
	}
	property :student_number, String, :required => true, :field_title => "Student Number", :length => 7,
	:messages => {
		:presence 	=> "Please provide your student number",
		:length		=> "Must be 7 digits"
	}
	property :mac_email, String, :required => true, :field_title => "McMaster Email", :format => :email_address, :unique => true,
	:messages => {
		:presence 	 => "Please provide your mac email address",
      	:format   	 => "Invalid email address",
      	:is_unique	 => "Email already used"
	}
	property :alternate_email, String, :required => true, :field_title => "Alternative Email", :format => :email_address, :unique => true,
	:messages => {
		:presence 	 => "Please provide an alternative email address",
      	:format   	 => "Invalid email address",
      	:is_unique	 => "Email already used"
	}
	property :phone_number, String, :required => true, :field_title => "Phone Number",
	:messages => {
		:presence 	=> "Please provide your phone number",
	}
	property :permanent_address, String, :required => true, :field_title => "Permanent Address",
	:messages => {
		:presence 	=> "Please provide your permanent address"
	}
	property :current_address, String, :required => true, :field_title => "Current Address",
	:messages => {
		:presence 	=> "Please provide your current address"
	}
	property :gender, String, :required => true, :field_title => "Gender"

	property :question1, String,  :field_title => "Which position(s) interest you the most. (Please refer to our Job Catalogue for details)"
	property :question2, String,  :field_title => "List your top 3 relevant professional experiences in chronological order. Include dates, employer, and what experiences you gained."
	property :question3, String,  :field_title => "What is your main goal and motivation to become part of AIESEC?"
	property :question4, String,  :field_title => "What skills would you like to develop by being involved with AIESEC?"
	property :question5, String,  :field_title => "What does leadership mean to you? Name 3 key skills or traits you possess. (eg. Strategic thinking, patience, methodical)"
	property :question6, String,  :field_title => "What type of person do you enjoy working with?"
	property :question7, String,  :field_title => "Describe a situation in which you had a lot of things to do at the same time and how you managed fulfill all responsibilities on time."

	property :newfield, String, :field_title => "new field"

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
		model_properties(Candidate, :full_name, :current_address).each do |field, name|
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
			:pagenum => "2",
			:fields => model_properties(Candidate, :question1, :question7)
	 	}
	end

	post '/:ca/pagetwo/process' do |ca|
		c = Candidate.first(:hex => ca)

		model_properties(Candidate, :question1, :question7).each do |field|
			c[field] = params[field]
		end

		c.save

		redirect "/#{c.hex}/pagethree"
	end

	get '/:ca/pagethree' do |ca|
		c = Candidate.first(:hex => ca)
		haml :pagethree, :locals => {
		    :c => c,
			:action => "/#{c.hex}/pagethree/process",
			:pagenum => "3",
			:fields => model_properties(Candidate, :newfield, :newfield)
	   	}
	end

	post '/:ca/pagethree/process' do |ca|
		c = Candidate.first(:hex => ca)

		model_properties(Candidate, :newfield, :newfield).each do |field|
			c[field] = params[field]
		end

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