#!/home/syou6162/local/bin/ruby -I.

$LOAD_PATH.unshift '/home/syou6162/local/lib'
ENV['GEM_HOME'] ||= '/home/syou6162/local/rubygems'
Encoding.default_external = 'UTF-8'
load 'start.rb'
set :run => false, :environment => :cgi

Rack::Handler::CGI.run Sinatra::Application

