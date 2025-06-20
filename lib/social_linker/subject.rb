# frozen_string_literal: true

module SocialLinker
  class Subject
    # Constant defining how the different share-url's look like and their parameters;
    # the parameters can be set in the options directly, or will be derived from more
    # generic options
    SHARE_TEMPLATES = {
      email: {
        base: "mailto:emailaddress?",
        params: [:subject, :body, :cc, :bcc]
      },
      pinterest: {
        base: "https://pinterest.com/pin/create/button/?",
        params: {url: :share_url, media: :media, description: :title}
      },
      linkedin: {
        base: "https://www.linkedin.com/shareArticle?mini=true&",
        params: {url: :share_url, title: :title, summary: :summary, source: :source}
      },
      google: {
        base: "https://plus.google.com/share?",
        params: {url: :share_url}
      },
      twitter: {
        base: "https://twitter.com/intent/tweet?",
        params: {text: :twitter_text, via: :via, url: :share_url, hashtags: :hashtags}
      },
      twitter_native: {
        base: "twitter://post?",
        params: {message: :twitter_text_with_url_and_hashtags}
      },
      facebook: {
        base: "https://www.facebook.com/sharer/sharer.php?",
        params: {u: :share_url}
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
      if tags&.count&.> 0
        tags.map { |a| "##{camelize_tag_when_needed(a.to_s.delete("#")).strip}" }.join(" ")
      else
        ""
      end
    end

    # single world tags don't need any processing, but tags consisting of different words do (before they can use in hashtags following convention)
    #
    # @param [String] tag to might need conversion
    # @return [String] fixed tag
    def camelize_tag_when_needed(tag)
      /\s/.match?(tag) ? tag.split(/\s/).collect { |a| a.capitalize }.join("") : tag
    end

    # default url accessor
    #
    # @return String with url
    def url
      @options[:url] || image_url
    end

    def image_url
      @options[:image_url]
    end

    def media_dimensions
      return @media_dimensions if @media_dimensions
      if media
        @media_dimensions = @options[:media_dimensions]
        if @media_dimensions.is_a? Array
          @media_dimensions = {
            width: @media_dimensions[0],
            height: @media_dimensions[1]
          }
        end
        @media_dimensions ||= {
          width: @options[:media_width],
          height: @options[:media_height]
        }
      else
        @media_dimensions = {}
      end
    end

    def media_width
      media_dimensions[:width]&.to_i
    end

    def media_height
      media_dimensions[:height]&.to_i
    end

    def utm_parameters?
      [nil, true].include?(@options[:utm_parameters])
    end

    def utm_parameters
      if utm_parameters?
        {
          utm_source: "<%=share_source%>",
          utm_medium: "share_link",
          utm_campaign: "social"
        }
      end
    end

    def canonical_url
      prefix_domain((@options[:canonical_url] || @options[:url]), @options[:domain])
    end

    def share_url
      url_to_share = prefix_domain((@options[:share_url] || @options[:url]), @options[:domain])
      if utm_parameters?
        utm_url_params = utm_parameters.collect { |k, v| "#{k}=#{v}" unless url_to_share.match(k.to_s) }.compact.join("&")
        combine_with = /\?/.match?(url_to_share) ? "&" : "?"
        "#{url_to_share}#{combine_with}#{utm_url_params}"
      else
        url_to_share
      end
    end

    # default title accessor
    # @return String with title
    def title
      @options[:title] || strip_string(options[:summary], 120)
    end

    # default summary accessor
    # @return String with summary
    def summary(strip = false)
      summ = @options[:summary] || @options[:description]
      strip ? strip_string(summ, 300) : summ
    end

    # default media accessor
    # @return String with media-url
    def media
      @options[:media]
    end

    def filename_derived_image_type
      if media
        extension = media.to_s.split(".").last.downcase
        if extension == "jpg" || extension == "jpeg"
          "image/jpeg"
        elsif extension == "png"
          "image/png"
        elsif extension == "gif"
          "image/gif"
        end
      end
    end

    def image_type
      @options[:image_type] || filename_derived_image_type
    end

    # default tags accessor
    # @return Array<String> with tags
    def tags
      @options[:tags] || []
    end

    def hashtags
      @options[:hashtags]
    end

    # puts quotes around a string
    # @return [String] now with quotes.
    def quote_string(string)
      "“#{string}”" if string.to_s.strip != ""
    end

    # strips a string to the max length taking into account quoting
    # @param [String] string that is about to be shortened
    # @param [Integer] max_length of the string to be shortened (default 100)
    # @return [String] shortened to the max lenght
    def strip_string(string, max_length = 100)
      if string&.length&.> max_length
        ellipsis = "…"
        if string[-1] == "”"
          ellipsis = "#{ellipsis}”"
        end
        max_char = max_length - 1 - ellipsis.length
        string = string[0..max_char] + ellipsis
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
    # * width and height for the images
    # * description
    # * facebook_app_id
    # * twitter_username
    # * language
    # * site_title_postfix
    # * ... and more often medium specific attributes...
    #
    # Note by default tracking parameters are added, turn this off by passing
    # `utm_parameters: false`
    #
    # @params [Hash] options as defined above
    def initialize(options = {})
      # basic option syncing
      @options = {}
      merge!(options)
    end

    # Merges existing SocialLinker::Subject with a (potentially limited set of)
    # new options
    #
    # options accepts:
    # * tags
    # * url
    # * title
    # * image_url & image_type(image/jpeg, image/png)
    # * description
    # * facebook_app_id
    # * twitter_username
    # * render_site_title_postfix
    # * ... and more often medium specific attributes...
    #
    # Note by default tracking parameters are added, turn this off by passing
    # `utm_parameters: false`
    #
    # @params [Hash, SocialLinker::Subject] options as defined above
    # @return SocialLinker::Subject (self)
    def merge!(options)
      options = options.options if options.is_a? SocialLinker::Subject
      options[:render_site_title_postfix] = true if options[:render_site_title_postfix].nil?
      options[:u] ||= options[:url] if options[:url]
      options[:media] ||= options[:image_url] if options[:image_url]
      options[:subject] ||= options[:title] if options[:title]
      options[:via] ||= options[:twitter_username] if options[:twitter_username]
      options[:text] = "#{options[:title]} #{options[:url]}" unless options[:text] # facebook & whatsapp native
      options[:domain] = options[:url].split("/")[0..2].join("/") if options[:url] && !options[:domain]
      options.select! { |k, v| !v.nil? }
      @options.merge!(options)

      if @options[:tags]
        @options[:tags].compact!
        @options[:hashtags] = @options[:tags][0..1].collect { |a| camelize_tag_when_needed(a) }.join(",") if @options[:tags] && !@options[:hashtags]
      end

      # make sure urls are absolute
      @options[:url] = prefix_domain(@options[:url], @options[:domain])
      @options[:image_url] = prefix_domain(@options[:image_url], @options[:domain])
      @options[:media] = prefix_domain(@options[:media], @options[:domain])

      @options.each do |k, v|
        @options[k] = v.strip if v.is_a? String
      end
      self
    end
    alias_method :update, :merge!

    # Generates a large body of text (typical for email)
    # @return String
    def body
      return options[:body] if options[:body]
      rv = ""
      rv += "#{summary}\n" if summary
      rv += "\n#{share_url}\n" if share_url
      rv += "\n#{description}\n" if summary != description && description
      rv += "\n#{@options[:media]}\n" if options[:media] != share_url && options[:media]
      rv += "\n\n#{hashtag_string(@options[:tags])}" if options[:tags]
      rv.strip!
      rv = nil if rv == ""
      rv
    end

    def description
      @options[:description] || @options[:summary]
    end

    # Turns the first two tags in to "tweetable" hash tags
    # Conform recommendation never to have more than 2 tags in a twitter message
    # @return String with two tags as #tags.
    def twitter_hash_tags
      options[:tags] ? hashtag_string(options[:tags][0..1]) : ""
    end

    # Generates the text to tweet (Twitter)
    # @return String with text to tweet
    def twitter_text
      return options[:twitter_text] if options[:twitter_text]
      return options[:tweet_text] if options[:tweet_text]

      max_length = 140 - (twitter_hash_tags.length + 12 + 4) # hashstring + url length (shortened) + spaces
      quote_string(strip_string(@options[:title], max_length))
    end

    # Generates a full twitter message includig url and hashtags
    # @return String with full twitter message (typically for native app)
    def twitter_text_with_url_and_hashtags
      return options[:twitter_text_with_url_and_hashtags] if options[:twitter_text_with_url_and_hashtags]
      return options[:message] if options[:message]
      return options[:status] if options[:status]
      [twitter_text, twitter_hash_tags, share_url].delete_if { |a| a.nil? or a.empty? }.join(" ")
    end
    alias_method :status, :twitter_text_with_url_and_hashtags

    def mastodon_text_with_url_and_hashtags
      return options[:twitter_text_with_url_and_hashtags] if options[:twitter_text_with_url_and_hashtags]
      return options[:message] if options[:message]
      return options[:status] if options[:status]
      [twitter_text, share_url, twitter_hash_tags].delete_if { |a| a.nil? or a.empty? }.join("\n\n")
    end

    # It is assumed that paths are relative to the domainname if none is given
    # @param [String] path to file (if it is already a full url, it will be passed along)
    # @param [String] domain of the file
    # @return String with full url
    def prefix_domain path, domain
      if path && !path.include?("//")
        [
          domain.gsub(/\/$/, ""),
          path.gsub(/^\//, "")
        ].join("/")
      else
        path
      end
    end

    # Returns the given options, extended with the (derived) defaults
    #
    # @return Hash with the options
    attr_reader :options

    # Generates a share link for each of the predefined platforms in the `SHARE_TEMPLATES` constant
    #
    # @param [Symbol] platform to generate the link for
    def share_link(platform)
      share_options = SHARE_TEMPLATES[platform]
      raise "No share template defined" unless share_options

      url_params = {}
      share_options[:params].each do |k, v|
        value_key = v || k # smartassery; v = nil for arrays
        value = options[value_key]
        value = send(value_key) if methods.include?(value_key)
        if value.to_s.strip != ""
          value = value.gsub("<%=share_source%>", platform.to_s)
          url_params[k] = value
        end
      end

      share_options[:base] + url_params.collect { |k, v| "#{k}=#{url_encode(v)}" }.join("&")
    end

    def url_encode(v)
      ERB::Util.url_encode(v)
    end

    # Catches method missing and tries to resolve them in either an appropriate share link or option value
    def method_missing(m, *args)
      share_link_matcher = m.to_s.match(/([a-z]*)_share_link/)
      if share_link_matcher
        share_link(share_link_matcher[1].to_sym)
      elsif options[m]
        options[m]
      else
        super
      end
    end
  end
end
