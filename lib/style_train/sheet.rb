module StyleTrain
  class Sheet
    attr_accessor :output, :indent_level
    
    def initialize(opts={})
      self.output = ''
      self.indent_level = 0
    end
    
    def render render_method = :content
      self.output = ''
      if render_method == :content
        content
      else
        send render_method
      end
      output
    end
    
    def style(selector)
      self.output << "\n"
      if selector.is_a?(String) || TAGS.include?(selector)
        self.output << "#{selector}"
      else  
        self.output << ".#{selector}"
      end
      self.output << " {"
      if block_given?
        self.indent_level += 2
        yield 
        self.indent_level -= 2
      end
      self.output << "\n}\n"
    end
    
    TAGS = [
      :a, :abbr, :acronym, :address, :area, :b, :base, :bdo, 
      :big, :blockquote, :body, :br, :button, :caption, :center, 
      :cite, :code, :col, :colgroup, :dd, :del, :dfn, :div, 
      :dl, :dt, :em, :embed, :fieldset, :form, :frame, :frameset, 
      :h1, :h2, :h3, :h4, :h5, :h6, :head, :hr, :html, :i, :iframe, 
      :img, :input, :ins, :kbd, :label, :legend, :li, :link, 
      :map, :meta, :noframes, :noscript, :object, :ol, :optgroup, 
      :option, :p, :param, :pre, :q, :s, :samp, :script, :select, 
      :small, :span, :strike, :strong, :sub, :sup, :table, 
      :tbody, :td, :textarea, :tfoot, :th, :thead, :title, 
      :tr, :tt, :u, :ul, :var
    ]
    
    TAGS.each do |tag|
      class_eval <<-RUBY
        def #{tag} &block
          style( '#{tag}', &block )
        end
      RUBY
    end
    
    def indent
      " " * indent_level
    end
    
    def property( label, value )
      value = value.join(' ') if value.is_a?(Array)
      self.output << "\n#{indent}#{label}: #{value};"
    end
    
    def background( opts )
      str = ""
      str << property('background-color', Color.new(opts[:color])) if opts[:color]
      str << property('background-image', opts[:image]) if opts[:image]
      str << property('background-position', opts[:position]) if opts[:position]
      str << property('background-attachment', opts[:attachment]) if opts[:attachment]
      str << property('background-repeat', background_repeat_value(opts[:repeat])) if opts[:repeat]
      str
    end
    
    def background_repeat_value(value)
      value = value.to_sym
      if value == :x || value == :y
        "repeat-#{value}"
      else
        value
      end
    end
    
    def border(opts={})
      value = border_value(opts)
      if only = opts[:only]
        if only.is_a?(Array)
          str = ""
          only.each do |type|
            str << property( "border-#{type}", value )
          end
          str
        else
          property "border-#{only}", value
        end
      else
        property "border", value
      end
    end
    
    def border_value(opts)
      color = opts[:color] || 'black'
      style = opts[:style] || 'solid'
      width = opts[:width] || '1px'
      "#{width} #{style} #{color}"
    end
    
    def outline(opts={})
      value = border_value(opts)
      property "outline", value
    end
    
    def text(opts)
      str = ""
      str << property('font-family', opts[:font]) if opts[:font]
      str << property('font-weight', opts[:weight]) if opts[:weight]
      str << property('font-variant', opts[:variant]) if opts[:variant]
      str << property('font-style', opts[:style]) if opts[:style]
      str << property('font-size', opts[:size]) if opts[:size]
      str << property('color', opts[:color]) if opts[:color]
      str << property('text-direction', opts[:direction]) if opts[:direction]
      str << property('letter-spacing', opts[:spacing]) if opts[:spacing]
      str << property('line-height', opts[:line_height]) if opts[:line_height]
      str << property('text-align', opts[:align]) if opts[:align]
      str << property('text-decoration', opts[:decoration]) if opts[:decoration]
      str << property('text-indent', opts[:indent]) if opts[:indent]
      str << property('text-transform', opts[:transform]) if opts[:transform]
      str << property('vertical-align', opts[:vertical_align]) if opts[:vertical_align]
      str << property('white-space', opts[:white_space]) if opts[:white_space]
      str << property('word-spacing', opts[:word_spacing]) if opts[:word_spacing]
      str
    end
    
    def list(opts)
      str = ""
      str << property('list-style-image', opts[:image]) if opts[:image]
      str << property('list-style-type', opts[:type]) if opts[:type]
      str << property('list-style-position', opts[:position]) if opts[:position]
      str
    end
    
    def margin(opts)
      if opts.is_a?(Array)
        property('margin', opts)
      else
        str = ""
        str << property('margin-left', opts[:left]) if opts[:left]
        str << property('margin-top', opts[:top]) if opts[:top]
        str << property('margin-bottom', opts[:bottom]) if opts[:bottom]
        str << property('margin-right', opts[:right]) if opts[:right]
        str
      end
    end
    
    def padding(opts)
      if opts.is_a?(Array)
        property('padding', opts)
      else
        str = ""
        str << property('padding-left', opts[:left]) if opts[:left]
        str << property('padding-top', opts[:top]) if opts[:top]
        str << property('padding-bottom', opts[:bottom]) if opts[:bottom]
        str << property('padding-right', opts[:right]) if opts[:right]
        str
      end
    end
    
    def position(opts)
      if opts.is_a?(Hash)
        str = ""
        str << property('position', opts[:type]) if opts[:type]
        str << property('bottom', opts[:bottom]) if opts[:bottom]
        str << property('top', opts[:top]) if opts[:top]
        str << property('left', opts[:left]) if opts[:left]
        str << property('right', opts[:right]) if opts[:right]
        str << property('float', opts[:float]) if opts[:float]
        str << property('clear', opts[:clear]) if opts[:clear]
        str << property('display', opts[:display]) if opts[:display]
        str << property('visibility', opts[:visibility]) if opts[:visibility]
        str << property('z-index', opts[:z_index]) if opts[:z_index]
        str << property('overflow', opts[:overflow]) if opts[:overflow]
        str << property('overflow-x', opts[:overflow_x]) if opts[:overflow_x]
        str << property('overflow-y', opts[:overflow_y]) if opts[:overflow_y]
        str << property('clip', "rect(#{opts[:clip].join(' ')})") if opts[:clip]
        str
      else
        property('position', opts)
      end
    end
    
    def table_options(opts)
      str = ""
      str << property('border-collapse', opts[:border]) if opts[:border]
      str << property('border-spacing', opts[:border_spacing]) if opts[:border_spacing]
      str << property('caption-side', opts[:caption]) if opts[:caption]
      str << property('empty-cells', opts[:empty]) if opts[:empty]
      str << property('table-layout', opts[:layout]) if opts[:layout]
      str 
    end
    
    def overflow(opts)
      if opts.is_a?(Hash)
        str = ""
        str << property( 'overflow-x', opts[:x]) if opts[:x]
        str << property( 'overflow-y', opts[:y]) if opts[:y]
        str
      else
        property 'overflow', opts
      end
    end
    
    [
      'color', 'display', 'float', 'clear', 'visibility', 'cursor',
      'height', 'width', 'max_height', 'max_width', 'min_height', 'min_width' 
    ].each do |meth|
      class_eval <<-RUBY
        def #{meth}(value)
          property('#{meth.dasherize}', value)
        end
      RUBY
    end
    
    
    def content
      # override me in subclasses
    end
    
    def self.render(render_method=:content)
      new.render(render_method)
    end
  end
end