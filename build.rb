# -*- coding: utf-8 -*-
require "rubygems"
require "mechanize"
require "optparse"
require "hpricot"
require "text/hatena"
require "entry"
require 'yaml'
require "suffix_array"
require "pp"

config = YAML.load_file("config.yaml")

result = []

Dir.glob("#{config["base_dir"]}/*.txt").reverse.each{|filename|
  next if config["excluding_files"].include?(filename.split("/")[-1])
  entries = Entries.new(filename)
  entries.entries.each{|entry|
    result.push entry
  }
}

File.open(config["entries"], "w") {|f|
  f.write Marshal.dump(result)
}

