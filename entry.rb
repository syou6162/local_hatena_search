# -*- coding: utf-8 -*-

require "text/hatena"
require "suffix_array"
require "fixed_text_hatena"
require 'nokogiri'

class Entry
  attr_reader :filename
  attr_reader :year
  attr_reader :month
  attr_reader :day
  attr_reader :point
  attr_reader :title
  attr_reader :categories
  attr_reader :content
  attr_reader :sa
  def initialize(args = {})
    @filename = args[:filename]
    @point = args[:point]
    @categories = args[:categories] || []
    @content = convert_to_hatena(args[:content])
    @sa = SuffixArray.new(args[:content])
  end

  def search(query)
    @sa.search(query)
  end
 
  def convert_to_hatena(text)
    if @filename.split("/")[-1] =~ /(\d{4})-(\d{2})-(\d{2}).txt/
      @year, @month, @day = $1, $2, $3
    end
    parser = Text::Hatena.new({:ilevel => 0, 
                                :permalink => "./#{@year}#{@month}#{@day}/#{@point}"})
    # amazonのところはうまくいかないので(画像が入ってるから?)
    text.gsub!(/((asin|ISBN):(.*?)):(title|detail|image)/){$1}
    parser.parse(text) 
    html = parser.html
    source = Nokogiri::HTML.parse(html)
    (source/"div.section>h3").each{|item|
      @title = item.inner_text
    }
    return html
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
    f = File.open(@filename, "r:utf-8")
    text = f.read
    f.close

    result = []
    content = ""
    prev_point = nil
    current_point = nil
    entries_size = 0
    text.split("\n").each{|line|
      if line =~ /^\*(\d{9,10})\*(.*)$/
        current_point = $1
        categories = []
        $2.scan(/\[(.*?)\]/){|category|
          unless category.to_s =~ /^http(.*)$/
            categories.push category
          end
        }
        if entries_size != 0
          result.push Entry.new({:filename => @filename,
                                  :point => prev_point,
                                  :categories => categories,
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


