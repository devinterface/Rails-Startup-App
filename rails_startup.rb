#Used some code from:
#http://github.com/lackac/app_lego/tree
#http://github.com/Sutto/rails-template/blob/07b044072f3fb0b40aea27b713ca61515250f5ec/rails_template.rb
#http://github.com/ffmike/BigOldRailsTemplate/tree/master

require 'open-uri'
require 'yaml'
require 'base64'


def download(from, to = from.split("/").last)
  #run "curl -s -L #{from} > #{to}"
  file to, open(from).read
rescue
  puts "Can't get #{from} - Internet down?"
  exit!
end
 
def commit_state(comment)
  git :add => "."
  git :commit => "-am '#{comment}'"
end

# grab an arbitrary file from github
def file_from_repo(github_user, repo, sha, filename, to = filename)
  download("http://github.com/#{github_user}/#{repo}/raw/#{sha}/#{filename}", to)
end

current_app_name = File.basename(File.expand_path(root))

# Copy database.yml
run 'cp config/database.yml config/database.yml.example'

# Delete unnecessary files
run "rm README"
run "rm public/index.html"
run "rm public/favicon.ico"
run "rm public/robots.txt"
run "rm public/images/rails.png"

# Set up git repository
git :init
git :add => '.'

# Set up .gitignore files
run "touch tmp/.gitignore log/.gitignore vendor/.gitignore"
run %{find . -type d -empty | grep -v "vendor" | grep -v ".git" | grep -v "tmp" | xargs -I xxx touch xxx/.gitignore}
file '.gitignore', <<-END
.DS_Store
log/*.log
/log/*.pid
/coverage/*
tmp/**/*
config/database.yml
db/*.sqlite3
vendor/rails
tmp/sent_mails/*
END


# Installing common gems and plugins for basic application with BDD testing support 

## BDD gems and plugins
#gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
#gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'
#plugin 'rspec', :git => "git://github.com/dchelimsky/rspec.git"
#plugin 'rspec-rails', :git => "git://github.com/dchelimsky/rspec-rails.git"
#plugin 'cucumber', :git => "git://github.com/aslakhellesoy/cucumber.git"
#generate("rspec")
#generate("cucumber")

## Potentially Useful 
#gem 'activemerchant', :lib => 'active_merchant'
#gem 'rubyist-aasm', :lib => "aasm", :source => "http://gems.github.com"
#gem 'hpricot', :source => 'http://code.whytheluckystiff.net'
#gem 'RedCloth', :lib => 'redcloth'
#gem 'mislav-will_paginate', :lib => 'will_paginate',  :source => 'http://gems.github.com'
#gem "binarylogic-searchlogic", :lib     => 'searchlogic', :source  => 'http://gems.github.com', :version => '~> 2.0'
#plugin 'asset_packager', :git => 'git://github.com/sbecker/asset_packager.git'
#plugin 'exception_notifier', :git => 'git://github.com/rails/exception_notification.git'

#gem "cwninja-inaction_mailer", :lib => 'inaction_mailer/force_load', :source => 'http://gems.github.com', :env => 'development'


## Javascript section
if yes?("Will this app use jQuery instead of Prototype? (y/n)")
  run "rm -f public/javascripts/*"
  run "touch public/javascripts/application.js"
  download "http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js","public/javascripts/jquery.form.js"
  file_from_repo "ffmike", "jquery-validate", "master", "jquery.validate.min.js", "public/javascripts/jquery.validate.min.js"
  javascript_include_tags = '<%= javascript_include_tag "http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js", "http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.min.js", "jquery.validate.min.js", "jquery.form.js", "application", :cache => true  %>'
else
  download "http://livevalidation.com/javascripts/src/1.3/livevalidation_prototype.js", "public/javascripts/livevalidation.js"
  javascript_include_tags = '<%= javascript_include_tag :defaults, "livevalidation", :cache => true %>'
end

##CSS section
file_from_repo "joshuaclayton", "blueprint-css", "master/blueprint", "ie.css", "public/stylesheets/ie.css"
file_from_repo "joshuaclayton", "blueprint-css", "master/blueprint", "print.css", "public/stylesheets/print.css"
file_from_repo "joshuaclayton", "blueprint-css", "master/blueprint", "screen.css", "public/stylesheets/screen.css"

## Common layout elements
file 'app/views/layouts/_flashes.html.erb', <<-END
<div id="flash" class="flash">
  <% flash.each do |key, value| -%>
    <div id="flash_<%= key %>" class="<%= key %>"><%=h value %></div>
  <% end -%>
</div>
END

extra_stylesheet_tags = <<-END
  <%= stylesheet_link_tag 'screen', :media => 'screen, projection', :cache => true %>
  <%= stylesheet_link_tag 'print', :media => 'print', :cache => true %>
  <!--[if IE]>
    <%= stylesheet_link_tag 'ie', :media => 'screen, projection', :cache => true %>
  <![endif]-->
END

file 'app/views/layouts/application.html.erb', <<-END
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" 
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
    <title><%= @page_title || controller.action_name %></title>
    #{extra_stylesheet_tags}
    <%= stylesheet_link_tag 'application', :media => 'all', :cache => true %>
    #{javascript_include_tags}
    <%= yield :head %>
  </head>
  <body>
    <div class="container">
      <div id="header">this is the header</div>
      <hr class="space">
      <div class="span-15 prepend-1 colborder">
      <%= render :partial => 'layouts/flashes' -%>
      <%= yield %>
      </div>
      <div class="span-7 last">
        this is the right menu menu
        <div id="user_nav">
        <% if current_user %>
          <%= link_to "Edit Profile", edit_user_path(:current) %> |
          <%= link_to "Logout", logout_path %>
        <% else %>
          <%= link_to "Register", new_user_path %> |
          <%= link_to "Login", login_path %>
        <% end %>
      </div>
      </div>
      <hr class="space">
      <div id="footer">
        this is the footer
      </div>    
    </div>
  </body>
</html>
END


file 'public/stylesheets/application.css', <<-END
/* @group Live Validations */

.LV_validation_message {
	font-weight: bold;
	margin-left: 5px;	
}

.LV_valid {
	background:#E6EFC2;
	color:#264409;
	border-color:#C6D880;
}

.LV_invalid {
	background:#FBE3E4;
	color:#8a1f11;
	border-color:#FBC2C4;
}

.LV_invalid_field {
	border-color: red;
	border-width: 1px;
}

  /* @end */
/* embeds the openid image in the text field */
input#user_openid_identifier, input#user_session_openid_identifier {
  background: url(http://openid.net/images/login-bg.gif) no-repeat;
  background-color: #fff;
  background-position: 0 50%;
  color: #000;
  padding-left: 18px;
}
END

commit_state "Base application with plugins, gems and BDD testing support"


# Installing common gems and plugins for authentication support
rake('db:sessions:create')
file "db/migrate/#{Time.now.to_i}_create_users.rb", <<-END
  class CreateUsers < ActiveRecord::Migration
    def self.up
      create_table :users do |t|
        t.timestamps
        t.string :login, :null => false
        t.string :email, :null => false
        t.string :crypted_password, :null => false
        t.string :password_salt, :null => false
        t.string :persistence_token, :null => false
        t.integer :login_count, :default => 0, :null => false
        t.datetime :last_request_at
        t.datetime :last_login_at
        t.datetime :current_login_at
        t.string :last_login_ip
        t.string :current_login_ip
      end
      
      add_index :users, :login
      add_index :users, :email
      add_index :users, :persistence_token
      add_index :users, :last_request_at
    end

    def self.down
      drop_table :users
    end
  end
END

if yes?("Will #{current_app_name} have Open ID authentication support? (y/n)") 
  @use_openid = true
  plugin 'openid_authentication plugin', :git => 'git://github.com/rails/open_id_authentication.git'
  gem 'authlogic-oid', :lib => "authlogic_openid", :source => "http://gems.github.com"
  gem 'ruby-openid', :lib => 'openid'
  file "db/migrate/#{Time.now.to_i}_add_users_openid_field.rb", <<-END
class AddUsersOpenidField < ActiveRecord::Migration
  def self.up
    add_column :users, :openid_identifier, :string
    add_index :users, :openid_identifier

    change_column :users, :crypted_password, :string, :default => nil, :null => true
    change_column :users, :password_salt, :string, :default => nil, :null => true
  end

  def self.down
    remove_column :users, :openid_identifier
  end
end
END
end

gem 'authlogic', :lib => "authlogic", :source => "http://gems.github.com"
if @use_openid
  rake('open_id_authentication:db:create')  
end

#if yes?("Will #{current_app_name} have a role support? (y/n)")
#  puts "Setting up role support..."
#  plugin 'role_requirement', :git => 'git://github.com/timcharper/role_requirement.git'
#  generate("roles", "Role User")
#end


if not @use_openid
file 'app/models/user.rb', <<-END
class User < ActiveRecord::Base
  acts_as_authentic
end
END
else
file 'app/models/user.rb', <<-END
class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.openid_required_fields = [:nickname, :email]
  end

  private

  def map_openid_registration(registration)
    self.email = registration["email"] if email.blank?
    self.login = registration["nickname"] if login.blank?
  end

end
END
end

file 'app/models/user_session.rb', <<-END
class UserSession < Authlogic::Session::Base
end
END

file 'app/controllers/application_controller.rb', <<-END
class ApplicationController < ActionController::Base
  helper :all
  helper_method :current_user_session, :current_user
  filter_parameter_logging :password, :password_confirmation
  
  private
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end
  
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end
  
  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to account_url
      return false
    end
  end
  
  def store_location
    session[:return_to] = request.request_uri
  end
  
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
end
END

if not @use_openid
file 'app/controllers/users_controller.rb', <<-END
class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end
  
  def show
    @user = @current_user
  end

  def edit
    @user = @current_user
  end
  
  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to account_url
    else
      render :action => :edit
    end
  end
end
END
else
file 'app/controllers/users_controller.rb', <<-END
class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]
  
  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])
    @user.save do |result|
      if result
        flash[:notice] = "Account registered!"
        redirect_back_or_default account_url
      else
        render :action => 'new'
      end
    end
  end
  
  def show
    @user = @current_user
  end

  def edit
    @user = @current_user
  end
  
  def update
    @user = @current_user
    @user.attributes = params[:user]
    @user.save do |result|
      if result
        flash[:notice] = "Account updated!"
        redirect_to account_url
      else
        render :action => 'edit'
      end
    end
  end
end
END
end

if not @use_openid
file 'app/controllers/user_sessions_controller.rb', <<-END
class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  
  def new
    @user_session = UserSession.new
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end
  
  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default new_user_session_url
  end
end
END
else  
file 'app/controllers/user_sessions_controller.rb', <<-END
class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  
  def new
    @user_session = UserSession.new
  end
  
  def create
    @user_session = UserSession.new(params[:user_session])
    @user_session.save do |result|
      if result
        flash[:notice] = "Login successful!"
        redirect_back_or_default account_url
      else
        render :action => 'new'
      end
    end
  end
  
  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default new_user_session_url
  end
end
END
end


file 'app/views/users/new.html.erb', <<-END
<fieldset>
<legend>Register</legend>
<% form_for @user, :url => account_path do |f| %>
  <%= f.error_messages %>
  <%= render :partial => "form", :object => f %>
  <%= f.submit "Register" %>
<% end %>
</fieldset>
END

file 'app/views/users/edit.html.erb', <<-END
<fieldset>
<legend>Edit My Account</legend>
<% form_for @user, :url => account_path do |f| %>
  <%= f.error_messages %>
  <%= render :partial => "form", :object => f %>
  <%= f.submit "Update" %>
<% end %>
</fieldset>
<br />
<%= link_to "My Profile", account_path %>
END

file 'app/views/users/show.html.erb', <<-END
<p>
  <b>Login:</b>
  <%=h @user.login %>
</p>

<p>
  <b>Email:</b>
  <%=h @user.email %>
</p>

<p>
  <b>Login count:</b>
  <%=h @user.login_count %>
</p>

<p>
  <b>Last request at:</b>
  <%=h @user.last_request_at %>
</p>

<p>
  <b>Last login at:</b>
  <%=h @user.last_login_at %>
</p>

<p>
  <b>Current login at:</b>
  <%=h @user.current_login_at %>
</p>

<p>
  <b>Last login ip:</b>
  <%=h @user.last_login_ip %>
</p>

<p>
  <b>Current login ip:</b>
  <%=h @user.current_login_ip %>
</p>


<%= link_to 'Edit', edit_account_path %>
END

if not @use_openid
file 'app/views/users/_form.html.erb', <<-END
<p>
<%= form.label :login %><br />
<%= form.text_field :login %>
</p>
<p>
<%= form.label :email %><br />
<%= form.text_field :email %>
</p>
<p>
<%= form.label :password, form.object.new_record? ? nil : "Change password" %><br />
<%= form.password_field :password %>
</p>
<p>
<%= form.label :password_confirmation %><br />
<%= form.password_field :password_confirmation %>
</p>
END
else
file 'app/views/users/_form.html.erb', <<-END
<p>
<%= form.label :login %><br />
<%= form.text_field :login %>
</p>
<p>
<%= form.label :email %><br />
<%= form.text_field :email %>
</p>
<% if @user.openid_identifier.blank? %>
<p>
<%= form.label :password, form.object.new_record? ? nil : "Change password" %><br />
<%= form.password_field :password %>
</p>
<p>
<%= form.label :password_confirmation %><br />
<%= form.password_field :password_confirmation %>
</p>
<h2>Or use OpenID</h2>
<% end %>
<p>
  <%= form.label :openid_identifier, "OpenID URL" %><br />
  <%= form.text_field :openid_identifier %>
</p>
END
end

if not @use_openid
file 'app/views/user_sessions/new.html.erb', <<-END
<fieldset>
    <legend>Login</legend>
<% form_for @user_session, :url => user_session_path do |f| %>
  <%= f.error_messages %>
  <p>
  <%= f.label :login %><br />
  <%= f.text_field :login %>
  </p>
  <p>
  <%= f.label :password %><br />
  <%= f.password_field :password %>
  </p>
  <p>
  <%= f.check_box :remember_me %><%= f.label :remember_me %>
  </p>
  <p>
  <%= f.submit "Login" %>
  </p>
<% end %>
</fieldset>
<%= link_to "signup", signup_url  %>
END
else
file 'app/views/user_sessions/new.html.erb', <<-END
<fieldset>
    <legend>Login</legend>
<% form_for @user_session, :url => user_session_path do |f| %>
  <%= f.error_messages %>
  <p>
  <%= f.label :login %><br />
  <%= f.text_field :login %>
  </p>
  <p>
  <%= f.label :password %><br />
  <%= f.password_field :password %>
  </p>
  <h2>Or use OpenID</h2>
  <p>
    <%= f.label :openid_identifier, "OpenID URL" %><br />
    <%= f.text_field :openid_identifier %>
  </p>
  <p>
  <%= f.check_box :remember_me %><%= f.label :remember_me %>
  </p>
  <p>
  <%= f.submit "Login" %>
  </p>
<% end %>
</fieldset>
<%= link_to "signup", signup_url  %>
END
end

file 'config/routes.rb', <<-END
ActionController::Routing::Routes.draw do |map|
  map.resource :account, :controller => "users"
  map.resources :users
  map.resource :user_session
  map.root :controller => "user_sessions", :action => "new"
  map.login '/login/', :controller => "user_sessions", :action => "new"
  map.logout '/logout/', :controller => "user_sessions", :action => "destroy"
  map.signup '/signup/', :controller => "users", :action => "new"
end
END
   

commit_state "Added authentication support"

## tags
if yes?("Do you want tags in #{current_app_name}? (y/n)")
  puts "Setting up tagging table..."
  plugin 'acts_as_taggable_redux', :git => 'git://github.com/geemus/acts_as_taggable_redux.git'
  rake('acts_as_taggable:db:create')
  commit_state "Added taggings support"
end

rake('gems:install')

rake('db:migrate')

git :commit => "-a -m 'Initial commit'"

# Success!
puts "SUCCESS!"
