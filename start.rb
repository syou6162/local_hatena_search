# -*- coding: utf-8 -*-
require 'rubygems'
require 'yaml'
require 'sinatra'
require 'haml'
require 'sass'
require 'pp'
require 'date'
require 'entry'

require "suffix_array"

config = YAML.load_file("config.yaml")
entries = Marshal.load(File.open(config["entries"], "r"))

get '/' do
  @config = config
  @entries = []
  str = ""
  time = Time.now
  entries[0..9].each{|entry|
    @entries.push entry
  }
  haml :index
end

get '/searchdiary' do
  @config = config
  @entries = []
  @query = params[:query]
  entries.each{|entry|
    if entry.search(@query) != -1
       @entries.push entry
    end
  }
  haml :search
end

get '/\d{4}' do
  "year"
end

get '/\d{6}' do
  "month"
end

get '/\d{8}' do
  "day"
end

get %r{(\d{4})(\d{2})(\d{2})/(\d{9,10})} do
  @config = config
  year, month, day, point = params[:captures]
  entries.each{|entry|
    if entry.year == year && entry.month == month && 
        entry.day == day && entry.point == point
      @entry = entry
    end
  }
  haml :entry
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

