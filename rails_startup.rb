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
 
def from_devinterface_repo(github_user, from, to = from.split("/").last)
  download("http://github.com/#{github_user}/Rails-Startup-App/raw/master/#{from}", to)
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

puts "##########################################"
puts "  Initial setup"
puts "##########################################"

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


commit_state "Initial setup"

puts "##########################################"
puts "  Database support"
puts "##########################################"

# database
database = ask("Which database support #{current_app_name} will use? [mysql] [postgres] [sqlite (default)] ")

case database
when "mysql"
  db_username = ask("Please enter the development database username")
  db_password = ask("Please enter the development database password")
  db_host = ask("Please eneter the development database host (hit enter if using sockets)")
  db_host_string = db_host.nil? ? "" : "host: #{db_host}"
  file 'config/database.yml', <<-END  
# MySQL. Versions 4.1 and 5.0 are recommended.
#
# Install the MySQL driver:
# gem install mysql
# On Mac OS X:
# sudo gem install mysql -- --with-mysql-dir=/usr/local/mysql
# On Mac OS X Leopard:
# sudo env ARCHFLAGS="-arch i386" gem install mysql -- --with-mysql-config=/usr/local/mysql/bin/mysql_config
# This sets the ARCHFLAGS environment variable to your native architecture
# On Windows:
# gem install mysql
# Choose the win32 build.
# Install MySQL and put its /bin directory on your path.
#
# And be sure to use new-style password hashing:
# http://dev.mysql.com/doc/refman/5.0/en/old-client.html

development:
  adapter: mysql
  encoding: utf8
  reconnect: false
  database: #{current_app_name}_development
  pool: 5
  username: #{db_username}
  password: #{db_password}
  #{db_host_string}
  #socket: /tmp/mysql.sock

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test: &TEST
  adapter: mysql
  encoding: utf8
  reconnect: false
  database: #{current_app_name}_test<%= ENV['TEST_ENV_NUMBER'] %>
  pool: 5
  username: root
  password:
  socket: /tmp/mysql.sock

production:
  adapter: mysql
  encoding: utf8
  database: #{current_app_name}_production
  pool: 5
  username: root
  password:
  socket: /tmp/mysql.sock

staging:
  adapter: mysql
  encoding: utf8
  database: #{current_app_name}_staging
  pool: 5
  username: root
  password:
  socket: /tmp/mysql.sock

cucumber:
 <<: *TEST
END
when "postgresql"
  db_username = ask("Please enter the development database username")
  db_password = ask("Please enter the development database password")
  file 'config/database.yml', <<-END
# PostgreSQL. Versions 7.4 and 8.x are supported.
#
# Install the ruby-postgres driver:
#   gem install ruby-postgres
# On Mac OS X:
#   gem install ruby-postgres -- --include=/usr/local/pgsql
# On Windows:
#   gem install ruby-postgres
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
development:
  adapter: postgresql
  encoding: unicode
  database: #{current_app_name}_development
  pool: 5
  username: #{db_username}
  password: #{db_password}

  # Connect on a TCP socket. Omitted by default since the client uses a
  # domain socket that doesn't need configuration. Windows does not have
  # domain sockets, so uncomment these lines.
  #host: localhost
  #port: 5432

  # Schema search path. The server defaults to $user,public
  #schema_search_path: myapp,sharedapp,public

  # Minimum log levels, in increasing order:
  #   debug5, debug4, debug3, debug2, debug1,
  #   log, notice, warning, error, fatal, and panic
  # The server defaults to notice.
  #min_messages: warning

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test: &TEST
  adapter: postgresql
  encoding: unicode
  database: #{current_app_name}_test<%= ENV['TEST_ENV_NUMBER'] %>
  pool: 5
  username: postgres
  password:

production:
  adapter: postgresql
  encoding: unicode
  database: #{current_app_name}_production
  pool: 5
  username: postgres
  password: 99Schema@

staging:
  adapter: postgresql
  encoding: unicode
  database: #{current_app_name}_staging
  pool: 5
  username: postgres
  password: 99Schema@

cucumber:
 <<: *TEST
END
else # "sqlite"
  file 'config/database.yml', <<-END
# SQLite version 3.x
#   gem install sqlite3-ruby (not necessary on OS X Leopard)
development:
  adapter: sqlite3
  database: db/development.sqlite3
  pool: 5
  timeout: 5000

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test: &TEST
  adapter: sqlite3
  database: db/test<%= ENV['TEST_ENV_NUMBER'] %>.sqlite3
  pool: 5
  timeout: 5000

production:
  adapter: sqlite3
  database: db/production.sqlite3
  pool: 5
  timeout: 5000

staging:
  adapter: sqlite3
  database: db/staging.sqlite3
  pool: 5
  timeout: 5000

cucumber:
 <<: *TEST
END
end

commit_state "Database support"

puts "##########################################"
puts "  Javascript and CSS support"
puts "##########################################"
 

## Javascript section
if yes?("Will this app use jQuery instead of Prototype? (y/n)")
  run "rm -f public/javascripts/*"
  run "touch public/javascripts/application.js"
  run "curl -s -L http://jquery.malsup.com/form/jquery.form.js?2.36 > public/javascripts/jquery.form.js"
  run "curl -s -L http://jquery.malsup.com/form/jquery.form.js?2.36 > public/javascripts/jquery.form.js"
  run "curl -s -L http://jquery.malsup.com/form/jquery.form.js?2.36 > public/javascripts/jquery.form.js"
  javascript_include_tags = '<%= javascript_include_tag "http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js", "http://ajax.googleapis.com/ajax/libs/jqueryui/1.7.2/jquery-ui.min.js", "jquery.form.js", "application", :cache => true  %>'
else
  javascript_include_tags = '<%= javascript_include_tag :defaults, :cache => true %>'
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


commit_state "Javascript and CSS support"


puts "##########################################"
puts "  Authentication support"
puts "##########################################"

# Installing common gems and plugins for authentication support
puts "Setting up user authentication..." 
rake('db:sessions:create')
file "db/migrate/001_create_users.rb", <<-END
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
  gem 'authlogic-oid', :lib => "authlogic_openid", :source => 'http://gemcutter.org'
  gem 'ruby-openid', :lib => 'openid'
  file "db/migrate/002_add_users_openid_field.rb", <<-END
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

gem 'authlogic', :source => 'http://gemcutter.org'
if @use_openid
  rake('open_id_authentication:db:create')  
end

## models and controllers
from_devinterface_repo "devinterface", "auth/models/user_session.rb", "app/models/user_session.rb"
from_devinterface_repo "devinterface", "auth/controllers/application_controller.rb", "app/controllers/application_controller.rb" 

if not @use_openid
from_devinterface_repo "devinterface", "auth/models/user.rb", "app/models/user.rb"
from_devinterface_repo "devinterface", "auth/controllers/users_controller.rb", "app/controllers/users_controller.rb"
from_devinterface_repo "devinterface", "auth/controllers/user_sessions_controller.rb", "app/controllers/user_sessions_controller.rb"
else
from_devinterface_repo "devinterface", "auth_openid/models/user.rb", "app/models/user.rb"
from_devinterface_repo "devinterface", "auth_openid/controllers/users_controller.rb", "app/controllers/users_controller.rb"
from_devinterface_repo "devinterface", "auth_openid/controllers/user_sessions_controller.rb", "app/controllers/user_sessions_controller.rb"
end


##views 
from_devinterface_repo "devinterface", "auth/views/users/new.html.erb", "app/views/users/new.html.erb"
from_devinterface_repo "devinterface", "auth/views/users/edit.html.erb","app/views/users/edit.html.erb"
from_devinterface_repo "devinterface", "auth/views/users/show.html.erb", "app/views/users/show.html.erb"

if not @use_openid
from_devinterface_repo "devinterface", "auth/views/users/_form.html.erb", "app/views/users/_form.html.erb"
from_devinterface_repo "devinterface", "auth/views/user_sessions/new.html.erb", "app/views/user_sessions/new.html.erb"
else
from_devinterface_repo "devinterface", "auth_openid/views/users/_form.html.erb", "app/views/users/_form.html.erb"
from_devinterface_repo "devinterface", "auth_openid/views/user_sessions/new.html.erb", "app/views/user_sessions/new.html.erb"
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
   

commit_state "Authentication support"


puts "##########################################"
puts "  Useful gems/plugins and initializers"
puts "##########################################"

## Potentially Useful 
if yes?("Do you want other useful gems/plugins into #{current_app_name}? (y/n)")
  #gem 'activemerchant', :lib => 'active_merchant'
  gem 'aasm', :source => "http://gemcutter.org"
  gem 'hpricot', :source => "http://gemcutter.org"
  gem 'bluecloth', :source => "http://gemcutter.org"
  gem 'will_paginate', :source => "http://gemcutter.org"
  gem "searchlogic", :source => "http://gemcutter.org"
  #gem "metric_fu", :source => "http://gems.github.com" not yet moved to gemcutter
  plugin 'asset_packager', :source => "http://gemcutter.org"
  plugin 'exception_notifier', :source => "http://gemcutter.org"
end

# development only inaction_mailer
gem "inaction_mailer",  :source => "http://gemcutter.org", :env => 'development'

# rakefile for use with inaction_mailer
rakefile 'mail.rake', <<-END
namespace :mail do
  desc "Remove all files from tmp/sent_mails"
  task :clear do
    FileList["tmp/sent_mails/*"].each do |mail_file|
      File.delete(mail_file)
    end
  end
end
END

# initializers
initializer 'requires.rb', <<-END
Dir[File.join(RAILS_ROOT, 'lib', '*.rb')].each do |f|
  require f
end
END


initializer 'mail.rb', <<-END
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
  :address => "111.111.111.111",
  :port => 25,
  :domain => "example.com",
  :authentication => :login,
  :user_name => "devinterface@example.com",
  :password => "password"  
}
END

commit_state "Useful gems/plugins and initializers"


puts "##########################################"
puts "  Tagging support"
puts "##########################################"

# tags
if yes?("Do you want tags in #{current_app_name}? (y/n)")
  puts "Setting up tagging table..."
  plugin 'acts_as_taggable_redux', :git => 'git://github.com/geemus/acts_as_taggable_redux.git'
  rake('acts_as_taggable:db:create')
  commit_state "Added taggings support"
end

commit_state "Tagging support"


puts "##########################################"
puts "  BDD support"
puts "##########################################"

## BDD gems and plugins
gem 'factory_girl', 
    :lib => 'factory_girl', 
    :source => "http://gemcutter.org",
    :env => 'test'
gem 'shoulda', 
    :lib => 'shoulda', 
    :source => "http://gemcutter.org",
    :env => 'test'
gem 'rspec', 
    :lib => 'rspec', 
    :source => "http://gemcutter.org",
    :env => 'test'
gem 'rspec-rails', 
    :lib => 'rspec-rails', 
    :source => "http://gemcutter.org",
    :env => 'test'
gem 'cucumber', 
    :lib => 'cucumber', 
    :source => "http://gemcutter.org",
    :env => 'test'
gem 'webrat', 
    :lib => 'webrat', 
    :source => "http://gemcutter.org",
    :env => 'test'
generate("rspec")
generate("cucumber")
plugin 'sweatshop', :git => 'git://github.com/mdarby/sweatshop.git'
inside ('spec') {
  run "rm -rf fixtures" 
  spec_helper = File.open(File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb')), "a")
  spec_helper.puts "require 'factory_girl'"
  spec_helper.puts 'Dir.glob("#{RAILS_ROOT}/spec/factories/*.rb").each {|f| require f }'
  spec_helper.close
}
inside ('test') {
  run "rm -rf fixtures unit functional integration performance"
  run "mkdir factories"
}


commit_state "BDD support"

rake('gems:install')

rake('db:migrate')

rake('sweatshop:generate')

git :commit => "-a -m 'Initial commit'"

# Success!
puts "SUCCESS!"
