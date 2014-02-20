require 'sinatra'
require 'haml'
require 'data_mapper'
require 'dm-postgres-adapter'
require 'securerandom'
require 'rack-flash'  
require 'sinatra/redirect_with_flash'  
require './helpers/apphelper.rb'
require "sinatra/reloader" if development?
require 'sinatra/assetpack'

set :server, 'webrick'

configure :development do
	DataMapper::setup(:default, ENV['DATABASE_URL'] || "postgres://localhost/aiesecmember")
end

configure :production do
	DataMapper::setup(:default, ENV['DATABASE_URL'] || "postgres://anvcoxtcxvnqdf:HiCmxBNEp5qKnk8vqgDzMoaopz@ec2-54-197-251-18.compute-1.amazonaws.com:5432/d79ngjcqh34gvs")
end

DataMapper::Model.raise_on_save_failure = false
DataMapper::Property.accept_options(:field_title)

class Candidate
	include DataMapper::Resource

	property :id, Serial, :required => true

	property :full_name, String, :field_title => "Full Name"
	validates_presence_of :full_name, :message => "Please provide your full name", :when => [ :first_page ]

	property :prog_level, String, :field_title => "Program & Level"
    validates_presence_of :prog_level, :message => "Please provide your program and level", :when => [ :first_page ]

	property :birthdate, String, :field_title => "Birthdate"
	validates_presence_of :birthdate, :message => "Please provide your birthdate", :when => [ :first_page ]

	property :stud_num, String, :field_title => "Student Number"
	validates_presence_of :stud_num, :message => "Please provide your student number", :when => [ :first_page ]
	validates_length_of :stud_num, :within => (7..7), :message => "Make sure your student number is 7 characters", :when => [ :first_page ]

	property :mac_email, String, :field_title => "McMaster Email", :format => :email_address
	validates_presence_of :mac_email, :message => "Please provide your mac email address", :when => [ :first_page ]
	validates_format_of :mac_email, :as => :email_address, :message => "Invalid email format", :when => [ :first_page ]

	property :alt_email, String, :field_title => "Alternative Email", :format => :email_address
	validates_presence_of :alt_email, :message => "Please provide an alternative email address", :when => [ :first_page ]
	validates_format_of :alt_email, :as => :email_address, :message => "Invalid email format", :when => [ :first_page ]

	property :phone_num, String, :field_title => "Phone Number"
	validates_presence_of :phone_num, :message => "Please provide your phone number", :when => [ :first_page ]
	validates_format_of :phone_num, :with => /((\(\d{3}\) ?)|(\d{3}-))?\d{3}-\d{4}/, :message => "Phone number must follow this format: 123-456-7890", :when => [ :first_page ]

	property :perm_address, String, :field_title => "Permanent Address"
	validates_presence_of :perm_address, :message => "Please provide your permanent address", :when => [ :first_page ]

	property :curr_address, String, :field_title => "Current Address"
	validates_presence_of :curr_address, :message => "Please provide your current address", :when => [ :first_page ]

	property :gender, String, :field_title => "Gender"
	validates_presence_of :gender, :when => [ :first_page ]

	property :q1, String, :field_title => "Which position(s) interest you the most. (Please refer to our Job Catalogue for details)"
	validates_presence_of :q1, :when => [ :second_page ]

	property :q2, String, :field_title => "List your top 3 relevant professional experiences in chronological order. Include dates, employer, and what experiences you gained."
	validates_presence_of :q2, :when => [ :second_page ]

	property :q3, String, :field_title => "What is your main goal and motivation to become part of AIESEC?"
	validates_presence_of :q3, :when => [ :second_page ]

	property :q4, String, :field_title => "What skills would you like to develop by being involved with AIESEC?"
	validates_presence_of :q4, :when => [ :second_page ]

	property :q5, String, :field_title => "What does leadership mean to you? Name 3 key skills or traits you possess. (eg. Strategic thinking, patience, methodical)"
	validates_presence_of :q5, :when => [ :second_page ]

	property :q6, String, :field_title => "What type of person do you enjoy working with?"
	validates_presence_of :q6, :when => [ :second_page ]

	property :q7, String, :field_title => "Describe a situation in which you had a lot of things to do at the same time and how you managed fulfill all responsibilities on time."
	validates_presence_of :q7, :when => [ :second_page ]

	property :y2014m01d15, Boolean, :field_title => "Wednesday, January 15th 2014"
	# validates_presence_of :y2014m01d15, :when => [ :third_page ]

	property :y2014m01d16, Boolean, :field_title => "Thursday, January 16th 2014"
	# validates_presence_of :y2014m01d16, :when => [ :third_page ]

	property :y2014m01d17, Boolean, :field_title => "Friday, January 17th 2014"
	# validates_presence_of :y2014m01d17, :when => [ :third_page ]

	property :created_at, DateTime
	property :hex, String, :unique => true

end

DataMapper.finalize.auto_migrate!

class Platform < Sinatra::Base

	#-------AUTH------------
	set :username, 'admin'
	set :token,'maketh1$longandh@rdtoremember'
	set :password,'eddie'


	#-------HELPERS-----------
	helpers Token
	helpers Sinatra::RedirectWithFlash
	helpers Property
	helpers Inflector
	helpers Auth

	#-------DEVELOPMENT-----------
	configure :development do
    	register Sinatra::Reloader
    	also_reload './helpers/apphelper.rb'
  	end

  	#-------SETUP-----------
  	enable :sessions
  	use Rack::Flash, :sweep => true  
  	#set :environment, :production
  	register Sinatra::AssetPack
  	

  	#-------ASSETS-----------
	assets do

  			# serve '/js', :from => 'public/js'
		# js :application, [
		# 	'/js/jquery-1.10.2.js',
		# 	'/js/scheduler.js'
		# 	# You can also do this: 'js/*.js'
		# ]

		serve '/css', :from => 'public/css'
		css :application, [
			'/css/reset.css',
			'/css/styles.css'
		]

	end	


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
   		if c.save(:first_page)
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

		model_properties(Candidate, :q1, :q7).each do |field, name|
			c[field] = session[field] = params[field]
		end

		#save record
   		if c.save(:second_page)
     		redirect "/#{c.hex}/pagethree"
   		else
   			#error on save, show error messages
   			c.attributes.each do |a|
   				field = a.first
				flash[field] = c.errors.on(field) ? c.errors.on(field).first : nil
			end
     		redirect "/#{c.hex}/pagetwo"
  		end

	end

	get '/:ca/pagethree' do |ca|
		c = Candidate.first(:hex => ca)
		haml :pagethree, :locals => {
		    :c => c,
			:action => "/#{c.hex}/pagethree/process",
			:pagenum => "3",
			:fields => model_properties(Candidate, :y2014m01d15, :y2014m01d17)
	   	}

	end

	post '/:ca/pagethree/process' do |ca|
		c = Candidate.first(:hex => ca)

		model_properties(Candidate, :y2014m01d15, :y2014m01d17).each do |field, name|
			c[field] = session[field] = params[field] == 'on' ? true : false
		end

		#save record
   		if c.save
     		redirect "/#{c.hex}/complete"
   		else
   			#error on save, show error messages
   			c.attributes.each do |a|
   				field = a.first
				flash[field] = c.errors.on(field) ? c.errors.on(field).first : nil
			end
     		redirect "/#{c.hex}/pagethree"
  		end
	end

	get '/:ca/complete' do |ca|
		c = Candidate.first(:hex => ca)
		haml :complete, :locals => {
		    :c => c
	   	}
	end

	get '/login/?' do
		haml :login, :layout => false

	end

	post '/login' do
		if params['username']==settings.username&&params['password']==settings.password
      		response.set_cookie(settings.username,settings.token) 
      		redirect '/admin'
		else
      		"Username or Password incorrect."
    	end
	end

	get '/logout/?' do
		response.set_cookie(settings.username, false)
		"Logged out successfully."
	end


	get '/admin/?' do
		if not admin? ; redirect '/login' ; end

		haml :admin, :locals => { 
			:candidates => Candidate.all
		}
	end

	get '/admin/:id' do |id|
		if not admin? ; redirect '/login' ; end

		c = Candidate.get(id)
		haml :candidate, :layout => false, :locals => { 
			:c => c,
			:fields_info => model_properties(Candidate, :prog_level, :gender),
			:fields_questions => model_properties(Candidate, :q1, :q7),
			:fields_availability => model_properties(Candidate, :y2014m01d15, :y2014m01d17),
			:fields_created_at => model_properties(Candidate, :created_at, :created_at)
		}
	end

	not_found do  
  		halt 404, 'page not found'  
	end  

end