require "social_linker/version"
require "erb"
include ERB::Util

module SocialLinker

  # The main class of SocialLinker is the `SocialLinker::Subject`-class.
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
        params: {text: :title, via: :via, url: :url, hashtags: :hashtags}
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
      string = (tags and tags.count > 0) ? "##{tags.collect{|a| a.to_s.strip.gsub('#','')}.join(" #")}" : nil
      if string and string.length > 60
        puts "WARNING: string of tags longer than adviced lenght of 60 characters: #{string}"
      end
      string
    end

    # default url accessor
    #
    # @return String with url
    def url
      @options[:url]
    end

    # default title accessor
    # @return String with title
    def title
      @options[:title]
    end

    # default summary accessor
    # @return String with summary
    def summary
      @options[:summary]
    end

    # default media accessor
    # @return String with media-url
    def media
      @options[:media]
    end

    # default tags accessor
    # @return Array<String> with tags
    def tags
      @options[:tags]
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
    # * image_url
    #
    # @params [hash] options as defined above
    def initialize(options={})
      @options = options
      @options[:u] = @options[:url] unless options[:u]
      @options[:description] = @options[:summary] unless options[:description]
      @options[:summary] = @options[:description] unless options[:summary]
      @options[:title] = "#{ strip_string(@options[:summary], 120) }" unless options[:title]
      @options[:description] = @options[:title] unless @options[:description]
      @options[:subject] = @options[:title] unless @options[:subject]
      @options[:via] = @options[:twitter_username] unless @options[:via]
      @options[:url] = @options[:media] unless @options[:url]
      @options[:text] = "#{@options[:title]} #{@options[:url]}" unless @options[:text] #facebook & whatsapp native
      @options[:hashtags] = @options[:tags][0..1].join(",") if @options[:tags] and !@options[:hashtags]
      unless @options[:status]
        hash_string = @options[:tags] ? hashtag_string(@options[:tags][0..1]) : ""
        max_length = 140 - ((hash_string ? hash_string.length : 0) + 12 + 4) #hashstring + url length (shortened) + spaces
        @options[:status] = "#{quote_string(strip_string(@options[:title],max_length))} #{@options[:url]} #{hash_string}"
      end
      @options[:message] = @options[:status] unless @options[:message]
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
        url_params[k] = options[value_key] if options[value_key] and options[value_key].to_s.strip != ""
      end

      return share_options[:base]+url_params.collect{|k,v| "#{k}=#{url_encode(v)}"}.join('&')
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
