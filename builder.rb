# -*- coding: utf-8 -*-
require "rubygems"
require "yaml"
require "text/hatena"
require "entry"
require "pp"

class Builder
  attr_reader :config
  def initialize(config)
    @config = config
  end
  def convert_txt_filename_to_db_filename(txt_filename)
    @config["db_dir"] + "/" + txt_filename.split("/").last.sub("\.txt", "") + ".db"
  end
  def convert_db_filename_to_txt_filename(db_filename)
    @config["base_dir"] + "/" + db_filename.split("/").last.sub("\.db", "") + ".txt"
  end
  def get_entries
    entries = {}
    Dir.glob("#{@config["db_dir"]}/*.db").reverse.each{|filename|
      tmp = Marshal.load(File.open(filename, "r"))
      filename = convert_db_filename_to_txt_filename(filename)
      entries[filename] = tmp
    }
    return entries
  end

  def build
    Dir.glob("#{config["base_dir"]}/*.txt").reverse.each{|filename|
      next if config["excluding_files"].include?(filename.split("/")[-1])
      entries = {}
      puts filename
      Entries.new(filename).entries.each{|entry|
        entries[entry.point] = entry
      }
      File.open("#{config["db_dir"]}/#{filename.split("/").last.sub("\.txt", "")}.db", "w") {|f|
        f.write Marshal.dump(entries)
      }
    }
  end

  def rebuild(entry)
    f = File.open(config["base_dir"] + "/" + "touch.txt", "r")
    timestamp = f.read.first
    f.close
    if timestamp =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/
      year, month, day, hour, min, sec = $1, $2, $3, $4, $5, $6
      timestamp = Time.local(year, month, day, hour, min, sec)
    end
    return if (File::stat(entry.filename).mtime - timestamp) < 0 # 古くなかったら抜ける
    
    db_filename = convert_txt_filename_to_db_filename(entry.filename)
    entries = Marshal.load(File.open(db_filename, "r"))
    Entries.new(entry.filename).entries.each{|e|
      entries[e.point] = e
    }
    File.open(db_filename, "w") {|f|
      f.write Marshal.dump(entries)
    }
    return entries
  end

  def rebuild_all
    f = File.open(config["base_dir"] + "/" + "touch.txt", "r")
    timestamp = f.read.first
    f.close

    if timestamp =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/
      year, month, day, hour, min, sec = $1, $2, $3, $4, $5, $6
      timestamp = Time.local(year, month, day, hour, min, sec)
    end

    new_files = []
    Dir.glob("#{config["base_dir"]}/*.txt").each{|filename|
      if (File::stat(filename).mtime - timestamp) > 0
        new_files.push filename
      end
    }

    if !new_files.empty?
      new_files.each{|filename|
        entries = {}
        Entries.new(filename).entries.each{|entry|
          entries[entry.point] = entry
        }
        File.open(convert_txt_filename_to_db_filename(filename), "w") {|f|
          f.write Marshal.dump(entries)
        }
      }
    end
  end
end
