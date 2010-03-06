#!/home/syou6162/local/bin/ruby -I.
# -*- coding: utf-8 -*-
$LOAD_PATH.unshift '/home/syou6162/local/lib'
ENV['GEM_HOME'] ||= '/home/syou6162/local/rubygems'
Encoding.default_external = 'UTF-8'

require 'yaml'
require 'sinatra'
require 'haml'
require 'sass'
require 'date'
require 'entry'
require 'builder'
require "suffix_array"

config = YAML.load_file("config.yaml")
builder = Builder.new(config)
builder.rebuild_all
entries = builder.get_entries

get '/?' do
  @config = config
  @entries = []
  str = ""
  time = Time.now
  (0..9).each{|i|
    prev = time - 24 * 60 * 60 * i
    tmp = "#{time.year}-%02d-%02d"%[prev.month, prev.day]
    if entries.key?("#{config["base_dir"]}/#{tmp}.txt")
      (entries["#{config["base_dir"]}/#{tmp}.txt"]).values.each{|entry|
        @entries.push entry
      }
    end
  }
  haml :index
end

get '/searchdiary' do
  @config = config
  @entries = []
  @query = params[:query].force_encoding('UTF-8')
  entries.values.each{|hash|
    hash.values.each{|entry|
      if entry.search(@query) != -1
        @entries.push entry
      end
    }
  }
  @entries = @entries.sort{|a, b|
    a = Time.local(a.year, a.month, a.day)
    b = Time.local(b.year, b.month, b.day)
    (b <=> a)
  }
  haml :search
end

get %r{(\d{4})(\d{2})(\d{2})/(\d{9,10})} do # 個別エントリー
  @config = config
  year, month, day, point = params[:captures]
  entries.values.each{|hash|
    hash.values.each{|entry|
      if entry.year == year && entry.month == month && 
          entry.day == day && entry.point == point
        result = builder.rebuild(entry)
        if result
          entries[entry.filename] = result
          @entry = result[entry.point]
        else
          @entry = entry
        end
      end
    }
  }
  haml :entry
end

get %r{(\d{4})(\d{2})(\d{2})} do # 日付けのエントリーたち
  @config = config
  @entries = []
  year, month, day = params[:captures]
  entries.values.each{|hash|
    hash.values.each{|entry|
      if entry.year == year && entry.month == month && 
          entry.day == day 
        result = builder.rebuild(entry)
        if result
          entries[entry.filename] = result
          @entry = result[entry.point]
        else
          @entry = entry
        end
        @entries.push @entry
      end
    }
  }
  haml :day
end

get '/stylesheet.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :stylesheet
end
