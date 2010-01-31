# -*- coding: utf-8 -*-
require "text/hatena"
require "suffix_array"

class Entry
  attr_reader :filename
  attr_reader :point
  attr_reader :content
  attr_reader :sa
  def initialize(args = {})
    @filename = args[:filename]
    @point = args[:point]
    @content = convert_to_hatena(args[:content])
    @sa = SuffixArray.new(args[:content])
  end

  def search(query)
    @sa.search(query)
  end
 
  def convert_to_hatena(text)
    puts @filename
    parser = Text::Hatena.new({})
    # amazonのところはうまくいかないので(画像が入ってるから?)
    text.gsub!(/((asin|ISBN):(.*?)):(title|detail|image)/){$1}
    parser.parse(text) 
    return parser.html
  end
end

class Entries
  attr_reader :filename
  attr_reader :entries
  def initialize(filename)
    @filename = filename
    @entries = make_entries
  end
  def make_entries
    f = File.open(@filename, "r")
    text = f.read
    f.close

    result = []
    content = ""
    prev_point = nil
    current_point = nil
    entries_size = 0
    text.split("\n").each{|line|
      #      if line =~ /^\*(?:(\d{9,10}|[a-zA-Z]\w*))\*(.*)$/
      if line =~ /^\*(\d{9,10})\*(.*)$/
        current_point = $1
        if entries_size != 0
          result.push Entry.new({:filename => @filename,
                                  :point => prev_point,
                                  :content => content
                                })
        end
        prev_point = current_point
        content = line
        entries_size += 1
      else
        content += "\n" + line
      end
    }
    # 最後のEntryを追加
    result.push Entry.new({:filename => @filename,
                            :point => current_point,
                            :content => content
                          })
    return result
  end
end


