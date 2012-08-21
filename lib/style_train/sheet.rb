module StyleTrain
  class Sheet
    attr_accessor :output, :level, :contexts
    
    def initialize(opts={})
      self.output = []
      self.contexts = []
      self.level = 0
    end
    
    def render render_method = :content, opts={}
      self.output = [header]
      if render_method == :content
        content
      else
        send render_method
      end
      
      render_array(opts)
    end
    
    def render_array opts={}
      if opts[:type] 
        render_type = opts[:type]
      else
        render_type = :full
      end
      
      output.map{|s| s.is_a?(String) ? s : s.render( render_type ) }.join("\n")
    end
    
    def header
<<-CSS
/*
  Generated by StlyeTrain CSS generator via the class #{self.class}
*/
CSS
   end
    
    def style_options
      {:level => level, :context => context}
    end
    
    def style(*selectors, &block)
      s = Style.new( style_options.merge(:selectors => selectors) )
      add_style_to_queue(s, &block)
    end
    
    alias :c :style
    
    def id(*selectors, &block)
      selectors = selectors.map{|s| "##{s}"}
      style(*selectors, &block)
    end
    
    def concat(*selectors, &block)
      s = Style.new( style_options.merge(:selectors => selectors, :concat => true ) )
      add_style_to_queue(s, &block)
    end
    
    alias :cat :concat
    
    def child(*selectors, &block)
      s = Style.new( style_options.merge(:selectors => selectors, :child => true))
      add_style_to_queue(s, &block)
    end
    
    def attr(*selector, &block)
      selector = selector.map{|s| "[#{s}]"}
      concat(*selector, &block)
    end
    
    def add_style_to_queue(s, &block)
      self.output << s
      self.contexts.unshift( s )
      if block_given?
        self.level += 1
        yield
        self.level -= 1
      end
      self.contexts.shift
    end
    
    def context
      contexts.first
    end
    
    TAGS = StyleTrain::Style::TAGS
    
    TAGS.each do |tag|
      class_eval <<-RUBY
        def #{tag}(*selectors, &block)
          if selectors.size > 0
            selectors = selectors.map do |e|
              '#{tag}' + StyleTrain::Style.selector(e, :exclude_tags => true) 
            end  
            style( *selectors, &block )
          else
            style( '#{tag}', &block )
          end  
        end
      RUBY
    end
    
    
    def property( label, value )
      value = value.join(' ') if value.is_a?(Array)
      str = "#{label}: #{value};"
      self.context.properties << str
      str
    end
    
    def background( opts )
      str = ""
      if opts.is_a?(Hash)
        str << property('background-color', Color.new(opts[:color])) if opts[:color]
        str << property('background-image', "url('#{opts[:image]}')") if opts[:image]
        str << property('background-position', opts[:position]) if opts[:position]
        str << property('background-attachment', opts[:attachment]) if opts[:attachment]
        str << property('background-repeat', background_repeat_value(opts[:repeat])) if opts[:repeat]
      else
        str << property('background', opts )
      end
      str
    end
    
    def background_repeat_value(value)
      value = value.to_sym
      if value == :x || value == :y
        "repeat-#{value}"
      elsif value == :none
        'no-repeat'
      else
        value
      end
    end
    
    def border(*args)
      str = ""
      if args.size == 1
        opts = args.first
      else
        opts = args.last || {}
        none = true
      end
      
      
      if opts.is_a?(Hash)
        value = border_value(opts)
        if only = opts[:only]
          Array(only).flatten.each do |side| 
            value = :none if none
            str << property("border-#{side}", value) 
          end
        else  
          str << property( "border", value )
        end
      else
        str << property( "border", opts )
      end
      
      str
    end
    
    ['left', 'right', 'top', 'bottom'].each do |side|
      class_eval <<-RUBY
        def border_#{side}(opts={})
          property('border-#{side}', border_value(opts))
        end
      RUBY
    end
    
    
    def border_value(opts)
      if opts.is_a?(Hash)
        color = opts[:color] || 'black'
        style = opts[:style] || 'solid'
        width = opts[:width] || opts[:size] || '1px'
        "#{width} #{style} #{color}"
      else
        opts.to_s
      end
    end
    
    def outline(opts={})
      value = border_value(opts)
      property "outline", value
    end
    
    def text(opts)
      str = ""
      if family = opts[:font] || opts[:family]
        str << property('font-family', family)
      end
      str << property('font-weight', opts[:weight]) if opts[:weight]
      str << property('font-variant', opts[:variant]) if opts[:variant]
      str << property('font-style', opts[:style]) if opts[:style]
      str << property('font-size', opts[:size]) if opts[:size]
      str << property('color', opts[:color]) if opts[:color]
      str << property('text-direction', opts[:direction]) if opts[:direction]
      str << property('letter-spacing', opts[:spacing]) if opts[:spacing]
      if height = opts[:line_height] || opts[:height]
        str << property('line-height', height)
      end
      str << property('text-align', opts[:align]) if opts[:align]
      str << property('text-decoration', opts[:decoration]) if opts[:decoration]
      str << property('text-indent', opts[:indent]) if opts[:indent]
      str << property('text-transform', opts[:transform]) if opts[:transform]
      str << property('vertical-align', opts[:vertical_align]) if opts[:vertical_align]
      str << property('white-space', opts[:white_space]) if opts[:white_space]
      str << property('word-spacing', opts[:word_spacing]) if opts[:word_spacing]
      str
    end
    
    alias :font :text
    
    def list(opts)
      str = ""
      str << property('list-style-image', opts[:image]) if opts[:image]
      str << property('list-style-type', opts[:type]) if opts[:type]
      str << property('list-style-position', opts[:position]) if opts[:position]
      str
    end
    
    def margin(*opts)
      opts = opts.size == 1 ? opts.first : opts
      if opts.is_a?(Hash)
          str = ""
          str << property('margin-left', opts[:left]) if opts[:left]
          str << property('margin-top', opts[:top]) if opts[:top]
          str << property('margin-bottom', opts[:bottom]) if opts[:bottom]
          str << property('margin-right', opts[:right]) if opts[:right]
          str
      else
        property('margin', opts)
      end
    end
    
    def padding(*opts)
      opts = opts.size == 1 ? opts.first : opts
      if opts.is_a?(Hash)
        str = ""
        str << property('padding-left', opts[:left]) if opts[:left]
        str << property('padding-top', opts[:top]) if opts[:top]
        str << property('padding-bottom', opts[:bottom]) if opts[:bottom]
        str << property('padding-right', opts[:right]) if opts[:right]
        str
      else
        property('padding', opts)
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
    
    def opacity(value, opts={})
      value = value.to_f
      str = ""
      str << property( 'opacity', value )
      str << alpha( value.to_f*100 ) if opts[:alpha]
      str 
    end
    
    def alpha(value)
      property('filter', "alpha(opacity=#{(value.to_i)})")
    end
    
    [
      'color', 'display', 'float', 'clear', 'visibility', 'cursor',
      'height', 'width', 'max_height', 'max_width', 'min_height', 'min_width',
      "overflow_x", 'overflow_y', 'z_index' 
    ].each do |meth|
      class_eval <<-RUBY
        def #{meth}(value)
          property('#{meth.dasherize}', value)
        end
      RUBY
    end
    
    def corners(opts)
      str = ""
      if opts.is_a?(Hash)
        if opts[:left]
          str << corner_top_left( opts[:left] )
          str << corner_bottom_left( opts[:left] )
        end
        
        if opts[:right]
          str << corner_top_right( opts[:right] )
          str << corner_bottom_right( opts[:right] )
        end
        
        if opts[:top]
          str << corner_top_right( opts[:top] )
          str << corner_top_left( opts[:top] )
        end
        
        if opts[:bottom]
          str << corner_bottom_right( opts[:bottom] )
          str << corner_bottom_left( opts[:bottom] )
        end
        
        str << corner_top_left( opts[:top_left] )         if opts[:top_left]
        str << corner_top_right( opts[:top_right] )       if opts[:top_right]
        str << corner_bottom_left( opts[:bottom_left] )   if opts[:bottom_left]
        str << corner_bottom_right( opts[:bottom_right] ) if opts[:bottom_right]
      else
        str << property('border-radius', opts )
        str << property('-moz-border-radius', opts)
        str << property('-webkit-border-radius', opts)
      end
      str
    end
    
    def corner_top_left size
      str = ""
      str << property('border-top-left-radius', size)
      str << property('-moz-border-radius-topleft', size)
      str << property('-webkit-border-top-left-radius', size)
      str
    end
    
    def corner_bottom_left size
      str = ""
      str << property('border-bottom-left-radius', size)
      str << property('-moz-border-radius-bottomleft', size)
      str << property('-webkit-border-bottom-left-radius', size)
      str
    end
    
    def corner_top_right size
      str = ""
      str << property('border-top-right-radius', size)
      str << property('-moz-border-radius-topright', size)
      str << property('-webkit-border-top-right-radius', size)
      str
    end
    
    def corner_bottom_right size
      str = ""
      str << property('border-bottom-right-radius', size)
      str << property('-moz-border-radius-bottomright', size)
      str << property('-webkit-border-bottom-right-radius', size)
      str
    end
    
    def shadow(opts={})
      opts[:horizontal_offset] ||= default_shadow_offset
      opts[:vertical_offset] ||= default_shadow_offset
      opts[:blur] ||= default_shadow_offset
      opts[:color] ||= default_shadow_color
      str = ""
      str << property('box-shadow', shadow_options(opts))
      str << property('-webkit-box-shadow', shadow_options(opts))
      str << property('-moz-box-shadow', shadow_options(opts))
      str
    end
    
    def default_shadow_offset
      0.25.em # this can be overwritten on a class by class basis
    end
    
    def default_shadow_color
      :black # this too
    end
    
    def shadow_options(opts)
      "#{opts[:inner] ? 'inset ' : ''}#{opts[:horizontal_offset]} #{opts[:vertical_offset]} #{opts[:blur]} #{opts[:color]}"
    end
    
    def gradient(opts={})
      raise ArgumentError, "gradient styles require a :start and :end color" unless opts[:start] && opts[:end]
      opts[:from] ||= 'top'
      direction = opts[:from] == 'top' ? "left top, left bottom" : "left top, right top" 
      str = ""
      str << property('background', opts[:end])
      str << property('background', "-webkit-gradient(linear, #{direction}, from(#{opts[:start]}), to(#{opts[:end]}))")
      str << property('background', "-moz-linear-gradient(#{opts[:from]},  #{opts[:start]},  #{opts[:end]})")
      str
    end
    
    def content
      # override me in subclasses
    end
    
    def self.render(render_method=:content)
      new.render(render_method)
    end
    
    def self.export opts={}
      new.export opts
    end
    
    def export opts={}
      name = file_name(opts[:file_name]) 
      str = render(opts[:render_method] || :content), opts
      # sometimes still an array at this point, bad w/ruby 1.9
      str = str.respond_to?(:join) ? str.join : str 
      File.open("#{StyleTrain.dir}/#{file_name}.css", 'w'){ |f| f.write(str) }
    end
    
    def file_name name=nil
      name || self.class.to_s.underscore
    end
  end
end