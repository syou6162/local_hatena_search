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

entries = Marshal.load(File.open("hoge", "r"))
config = YAML.load_file("config.yaml")
base = "/Users/syou6162/hatena/syou6162/diary"

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

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end

