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
DataMapper::Model.raise_on_save_failure = true
DataMapper::Property.accept_options(:field_title)

class Candidate
	include DataMapper::Resource

	property :id, Serial, :required => true

	property :full_name, String, :field_title => "Full Name",
	:messages => {
		:presence 	=> "Please provide your full name"
	}
	#validates_presence_of :full_name, :when => [ :first_page ]

	property :prog_level, String, :field_title => "Program & Level",
    :messages => {
      	:presence 	 => "Please provide your program and level",
      	:format   	 => "Invalid email address"
    }
    #validates_presence_of :prog_level, :when => [ :first_page ]

	property :birthdate, String, :field_title => "Birthdate",
	:messages => {
		:presence 	=> "Please provide your birthdate"
	}
	#validates_presence_of :birthdate, :when => [ :first_page ]

	property :stud_num, String, :field_title => "Student Number", :length => 7,
	:messages => {
		:presence 	=> "Please provide your student number",
		:length		=> "Must be 7 digits"
	}
	#validates_presence_of :stud_num, :when => [ :first_page ]

	property :mac_email, String, :field_title => "McMaster Email", :format => :email_address,
	:messages => {
		:presence 	 => "Please provide your mac email address",
      	:format   	 => "Invalid email address"
	}
	#validates_presence_of :mac_email, :when => [ :first_page ]

	property :alt_email, String, :field_title => "Alternative Email", :format => :email_address,
	:messages => {
		:presence 	 => "Please provide an alternative email address",
      	:format   	 => "Invalid email address"
	}
	#validates_presence_of :alt_email, :when => [ :first_page ]

	property :phone_num, String, :field_title => "Phone Number",
	:messages => {
		:presence 	=> "Please provide your phone number"
	}
	#validates_presence_of :phone_num, :when => [ :first_page ]

	property :perm_address, String, :field_title => "Permanent Address",
	:messages => {
		:presence 	=> "Please provide your permanent address"
	}
	#validates_presence_of :perm_address, :when => [ :first_page ]

	property :curr_address, String, :field_title => "Current Address",
	:messages => {
		:presence 	=> "Please provide your current address"
	}
	#validates_presence_of :curr_address, :when => [ :first_page ]

	property :gender, String, :field_title => "Gender"
	#validates_presence_of :gender, :when => [ :first_page ]



	property :q1, String, :field_title => "Which position(s) interest you the most. (Please refer to our Job Catalogue for details)"
	#validates_presence_of :q1, :when => [ :second_page ]

	property :q2, String, :field_title => "List your top 3 relevant professional experiences in chronological order. Include dates, employer, and what experiences you gained."
	#validates_presence_of :q2, :when => [ :second_page ]

	property :q3, String, :field_title => "What is your main goal and motivation to become part of AIESEC?"
	#validates_presence_of :q3, :when => [ :second_page ]

	property :q4, String, :field_title => "What skills would you like to develop by being involved with AIESEC?"
	#validates_presence_of :q4, :when => [ :second_page ]

	property :q5, String, :field_title => "What does leadership mean to you? Name 3 key skills or traits you possess. (eg. Strategic thinking, patience, methodical)"
	#validates_presence_of :q5, :when => [ :second_page ]

	property :q6, String, :field_title => "What type of person do you enjoy working with?"
	#validates_presence_of :q6, :when => [ :second_page ]

	property :q7, String, :field_title => "Describe a situation in which you had a lot of things to do at the same time and how you managed fulfill all responsibilities on time."
	#validates_presence_of :q7, :when => [ :second_page ]

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
	     	:fields => model_properties(Candidate, :full_name, :curr_address)
   		}
	end

	post '/create' do 

		c = Candidate.new

		#save field parameters to record and session
		model_properties(Candidate, :full_name, :curr_address).each do |field, name|
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
			:fields => model_properties(Candidate, :q1, :q7)
	 	}
	end

	post '/:ca/pagetwo/process' do |ca|
		c = Candidate.first(:hex => ca)

		model_properties(Candidate, :q1, :q7).each do |field|
			c[field] = session[field] = params[field]
			puts session[field].inspect
		end

		c.save

		redirect "/#{c.hex}/pagethree"

		# #save record
  #  		if c.save(:first_page)
  #    		redirect "/#{c.hex}/pagethree"
  #  		else
  #  			#error on save, show error messages
  #  			c.attributes.each do |a|
  #  				field = a.first
  #  				puts field.inspect
		# 		flash[field] = c.errors.on(field) ? c.errors.on(field).first : nil
		# 	end
  #    		redirect "/#{c.hex}/pagetwo"
  # 		end

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
		haml :admin, :locals => { 
			:candidates => Candidate.all
		}
	end

	get '/admin/:id' do |id|
		c = Candidate.get(id)
		haml :candidate, :layout => false, :locals => { 
			:c => c,
			:fields_info => model_properties(Candidate, :prog_level, :gender),
			:fields_questions => model_properties(Candidate, :q1, :q7)
		}
	end

	not_found do  
  		halt 404, 'page not found'  
	end  

end