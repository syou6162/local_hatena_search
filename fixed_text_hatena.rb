# -*- coding: utf-8 -*-
require "text/hatena"
require "text/hatena/auto_link/http"
require "text/hatena/auto_link/tex"
require "text/hatena/node"
require "text/hatena/h3_node"

module Text
  class Hatena
    class H3Node < Node
      def parse
        c = @context
        return unless l = c.shiftline
        return unless @pattern =~ l
        name, cat, title = $1, $2, $3
        b = c.baseuri
        p = c.permalink
        t = "\t" * @ilevel
        sa = c.sectionanchor

        if cat
          cat.gsub!(/\[([^\:\[\]]+)\]/e) do
            w = $1
            ew = _encode($1)
            %Q![<a href="#{b}?word=#{ew}" class="sectioncategory">#{w}</a>]!
          end
        end
        name, extra = _formatname(name)
        name ||= ""
        cat ||= ""
        # ここをいじった
        c.htmllines(%Q!#{t}<h3><a href="#{p}" name="#{name}"><span class="sanchor">#{sa}</span></a> #{cat}#{title}</h3>#{extra}!)
      end
    end
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
