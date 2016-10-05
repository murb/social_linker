module SocialLinker
  class Subject

    # Constant defining how the different share-url's look like and their parameters;
    # the parameters can be set in the options directly, or will be derived from more
    # generic options
    SHARE_TEMPLATES = {
      email: {
        base: "mailto:emailaddress?",
        params: [:subject,:body,:cc,:bcc]
      },
      pinterest: {
        base: "https://pinterest.com/pin/create/button/?",
        params: {url: :url, media: :media, description: :title}
      },
      linkedin: {
        base: "https://www.linkedin.com/shareArticle?mini=true&",
        params: [:url, :title, :summary, :source]
      },
      google: {
        base: "https://plus.google.com/share?",
        params: [:url]
      },
      twitter: {
        base: "https://twitter.com/intent/tweet?",
        params: {text: :tweet_text, via: :via, url: :url, hashtags: :hashtags}
      },
      twitter_native: {
        base: "twitter://post?",
        params: [:message]
      },
      facebook: {
        base: "https://www.facebook.com/sharer/sharer.php?",
        params: [:u]
      },
      facebook_native: {
        base: "fb://publish/profile/me?",
        params: [:text]
      },
      whatsapp: {
        base: "whatsapp://send?",
        params: [:text]
      }

    }

    # convert an array of strings to a Twitter-like hashtag-string
    #
    # @param [Array] tags to be converted to string
    # @return [String] containing a Twitter-style tag-list
    def hashtag_string(tags)
      if tags and tags.count > 0
        tags = tags.collect{|a| camelize_tag_when_needed(a) }
        string = "##{tags.collect{|a| a.to_s.strip.gsub('#','')}.join(" #")}"
        if string and string.length > 60
          puts "WARNING: string of tags longer than adviced lenght of 60 characters: #{string}"
        end
        string
      end
    end

    # single world tags don't need any processing, but tags consisting of different words do (before they can use in hashtags following convention)
    #
    # @param [String] tag to might need conversion
    # @return [String] fixed tag
    def camelize_tag_when_needed(tag)
      tag = tag.to_s
      tag.match(/\s/) ? tag.split(/\s/).collect{|a| a.capitalize}.join("") : tag
    end

    # default url accessor
    #
    # @return String with url
    def url
      @options[:url]
    end

    def image_url
      @options[:image_url]
    end

    def utm_parameters
      [nil, true].include?(@options[:utm_parameters]) ? true : false
    end

    def canonical_url
      @options[:canonical_url]
    end

    # default title accessor
    # @return String with title
    def title
      @options[:title]
    end

    # default summary accessor
    # @return String with summary
    def summary(strip=false)
      strip ? strip_string(@options[:summary], 300) : @options[:summary]
    end

    # default media accessor
    # @return String with media-url
    def media
      @options[:media]
    end

    # default tags accessor
    # @return Array<String> with tags
    def tags
      @options[:tags] ? @options[:tags] : []
    end

    def hashtags
      @options[:hashtags]
    end

    # puts quotes around a string
    # @return [String] now with quotes.
    def quote_string(string)
      "“#{string}”" if string and string.to_s.strip != ""
    end

    # strips a string to the max length taking into account quoting
    # @param [String] string that is about to be shortened
    # @param [Integer] max_length of the string to be shortened (default 100)
    # @return [String] shortened to the max lenght
    def strip_string(string, max_length=100)
      if string and string.length > max_length
        elipsis = "…"
        if string[-1] == "”"
          elipsis = "#{elipsis}”"
        end
        max_char = max_length-1-elipsis.length
        string = string[0..max_char]+elipsis
      end
      string
    end

    # Initialize the SocialLinker::Subject
    #
    # options accepts:
    # * tags
    # * url
    # * title
    # * image_url & image_type(image/jpeg, image/png)
    # * description
    # * facebook_app_id
    # * twitter_username
    # * ... and more often medium specific attributes...
    #
    # Note by default tracking parameters are added, turn this off by passing
    # `utm_parameters: false`
    #
    # @params [Hash] options as defined above
    def initialize(options={})
      # basic option syncing
      @options = options
      @options[:facebook_app_id] = @options[:facebook_app_id]
      @options[:u] = @options[:url] unless options[:u]
      @options[:media] = @options[:image_url] unless options[:media]
      @options[:description] = @options[:summary] unless options[:description]
      @options[:summary] = @options[:description] unless options[:summary]
      @options[:title] = "#{ strip_string(@options[:summary], 120) }" unless options[:title]
      @options[:description] = @options[:title] unless @options[:description]
      @options[:subject] = @options[:title] unless @options[:subject]
      @options[:via] = @options[:twitter_username] unless @options[:via]
      @options[:url] = @options[:media] unless @options[:url]
      raise ArgumentError, "#{url} is not a valid url" if @options[:url] and !@options[:url].include?('//')

      @options[:text] = "#{@options[:title]} #{@options[:url]}" unless @options[:text] #facebook & whatsapp native
      @options[:canonical_url] = @options[:url]
      @options[:domain] = @options[:url].split(/\//)[0..2].join("/") if @options[:url] and !@options[:domain]

      if @options[:url] and utm_parameters
        unless @options[:url].match /utm_source/
          combine_with = @options[:url].match(/\?/) ? "&" : "?"
          @options[:url] = "#{@options[:url]}#{combine_with}utm_source=<%=share_source%>"
        end
        unless @options[:url].match /utm_medium/
          combine_with = "&"
          @options[:url] = "#{@options[:url]}#{combine_with}utm_medium=share_link"
        end
        unless @options[:url].match /utm_campaign/
          combine_with = "&"
          @options[:url] = "#{@options[:url]}#{combine_with}utm_campaign=social"
        end
      end
      if @options[:tags]
        @options[:tags].compact!
        @options[:hashtags] = @options[:tags][0..1].collect{|a| camelize_tag_when_needed(a) }.join(",") if @options[:tags] and !@options[:hashtags]
        @options[:hash_string] = @options[:tags] ? hashtag_string(@options[:tags][0..1]) : ""
      end
      unless @options[:tweet_text]
        max_length = 140 - ((@options[:hash_string] ? @options[:hash_string].length : 0) + 12 + 4) #hashstring + url length (shortened) + spaces
        @options[:tweet_text] = "#{quote_string(strip_string(@options[:title],max_length))}"
      end
      @options[:message] = [@options[:tweet_text],@options[:url],@options[:hash_string]].compact.join(" ") unless @options[:message]
      @options[:status] = @options[:message] unless @options[:status]

      # make sure urls are absolute
      @options[:url] = prefix_domain(@options[:url],@options[:domain])
      @options[:image_url] = prefix_domain(@options[:image_url],@options[:domain])
      @options[:media] = prefix_domain(@options[:media],@options[:domain])

      unless @options[:body]
        @options[:body] = ""
        @options[:body] += "#{@options[:summary]}\n" if @options[:summary]
        @options[:body] += "\n#{@options[:url]}\n" if @options[:url]
        @options[:body] += "\n#{@options[:description]}\n" if @options[:summary] != @options[:description] and @options[:description]
        @options[:body] += "\n#{@options[:media]}\n" if @options[:media] != @options[:url] and @options[:media]
        @options[:body] += "\n\n#{hashtag_string(@options[:tags])}" if @options[:tags]
        @options[:body] = nil if @options[:body].strip == ""
      end

      @options.each do |k,v|
        @options[k] = v.strip if v and v.is_a? String
      end
    end

    # It is assumed that paths are relative to the domainname if none is given
    # @param [String] path to file (if it is already a full url, it will be passed along)
    # @param [String] domain of the file
    # @return String with full url
    def prefix_domain path, domain
      return_string = path
      if path and !path.include?("//")
        path.gsub!(/^\//,'')
        domain.gsub!(/\/$/,'')
        return_string = [domain,path].join("/")
      end
      return_string
    end

    # Returns the given options, extended with the (derived) defaults
    #
    # @return Hash with the options
    def options
      @options
    end

    # Generates a share link for each of the predefined platforms in the `SHARE_TEMPLATES` constant
    #
    # @param [Symbol] platform to generate the link for
    def share_link(platform)
      share_options = SHARE_TEMPLATES[platform]
      raise "No share template defined" unless share_options

      url_params = {}
      share_options[:params].each do |k,v|
        value_key = v||k #smartassery; v = nil for arrays
        value = options[value_key]
        if value and value.to_s.strip != ""
          value = value.gsub('<%=share_source%>', platform.to_s)
          url_params[k] = value
        end
      end

      return share_options[:base]+url_params.collect{|k,v| "#{k}=#{url_encode(v)}"}.join('&')
    end

    def url_encode(v)
      ERB::Util.url_encode(v)
    end

    # Catches method missing and tries to resolve them in either an appropriate share link or option value
    def method_missing(m,*args)
      share_link_matcher = m.to_s.match(/([a-z]*)_share_link/)
      if share_link_matcher
        return share_link(share_link_matcher[1].to_sym)
      elsif options[m]
        return options[m]
      else
        super
      end
    end
  end
end

