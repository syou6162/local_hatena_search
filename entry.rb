# -*- coding: utf-8 -*-
require "text/hatena"
require "text/hatena/auto_link/http"
require "text/hatena/auto_link/tex"
require "suffix_array"

module Text
  class Hatena
    class AutoLink
      class Tex < Scheme
        # TeX記法がはてなじゃないと許してもらえないので他のところを利用させてもらう
        def parse(text, opt = {})
          return if @@pattern !~ text
          alt = escape_attr($1)
          tex = $1
          tex.gsub!(/\\([\[\]])/, '\1')
          tex.gsub!(/\s/, '~')
          tex.gsub!(/"/, '&quot;')
          return sprintf('<img src="http://formula.s21g.com/?%s.png" class="tex" alt="%s">',
                         tex, alt)
        end
      end
      class HTTP < Scheme
        # 毎回fetchしにいくと遅いのでurl自体をtitleに
        def _get_page_title(url) 
          return url
        end
      end
    end
    class HTMLFilter
      # slideshareがうまくいかないからいくつか編集
      def init
        @parser = HTMLSplit
        # objectとparamとembedを追加
        @allowtag = /^(a|abbr|acronym|address|b|base|basefont|big|blockquote|br|col|em|caption|center|cite|code|div|dd|del|dfn|dl|dt|fieldset|font|form|hatena|h\d|hr|i|img|input|ins|kbd|label|legend|li|meta|ol|optgroup|option|p|pre|q|rb|rp|rt|ruby|s|samp|select|small|span|strike|strong|sub|sup|table|tbody|td|textarea|tfoot|th|thead|tr|tt|u|ul|var|object|param|embed)$/
        # styleとnameとvalueとsrcとallowscriptaccessとallowfullscreenを追加
        @allallowattr = /^(accesskey|align|alt|background|bgcolor|border|cite|class|color|datetime|height|id|size|title|type|valign|width|style|name|value|src|allowscriptaccess|allowfullscreen)$/
        @allowattr = {
          :a => 'href|name|target',
          :base => 'href|target',
          :basefont => 'face',
          :blockquote => 'cite',
          :br => 'clear',
          :col => 'span',
          :font => 'face',
          :form => 'action|method|target|enctype',
          :hatena => '.+',
          :img => 'src',
          :input => 'type|name|value|tabindex|checked|src',
          :label => 'for',
          :li => 'value',
          :meta => 'name|content',
          :ol => 'start',
          :optgroup => 'label',
          :option => 'value',
          :select => 'name|accesskey|tabindex',
          :table => 'cellpadding|cellspacing',
          :td => 'rowspan|colspan|nowrap',
          :th => 'rowspan|colspan|nowrap',
          :textarea => 'name|cols|rows',
        }
      end
    end
  end
end

class Entry
  attr_reader :filename
  attr_reader :point
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
      if line =~ /^\*(\d{9,10}\*)(.*)$/
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


