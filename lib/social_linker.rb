require "social_linker/version"
require "erb"
include ERB::Util

module SocialLinker
  class Subject
    SHARE_TEMPLATES = {
      email: {
        base: "mailto:emailaddress?",
        params: [:subject,:body,:cc,:bcc]
      },
      pinterest: {
        base: "https://pinterest.com/pin/create/button/?",
        params: [:url, :media, :description]
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
        base: "https://twitter.com/home?",
        params: [:status]
      },
      facebook: {
        base: "https://www.facebook.com/sharer/sharer.php?",
        params: [:u]
      }

    }

    def hashtag_string(tags)
      string = (tags and tags.count > 0) ? "##{tags.collect{|a| a.to_s.strip.gsub('#','')}.join(" #")}" : nil
      if string and string.length > 60
        puts "WARNING: string of tags longer than adviced lenght of 60 characters: #{string}"
      end
      string
    end

    def quote_string(string)
      "“#{string}”" if string and string.to_s.strip != ""
    end

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

    # options accepts:
    # * tags
    # * url
    # * title
    # * image_url

    def initialize(options={})
      @options = options
      @options[:u] = @options[:url] unless options[:u]
      @options[:description] = @options[:summary] unless options[:description]
      @options[:summary] = @options[:description] unless options[:summary]
      @options[:title] = "#{ strip_string(@options[:summary], 120) }" unless options[:title]
      @options[:description] = @options[:title] unless @options[:description]
      @options[:subject] = @options[:title] unless @options[:subject]
      @options[:url] = @options[:media] unless @options[:url]

      unless @options[:status]
        hash_string = hashtag_string(@options[:tags])
        max_length = (hash_string ? hash_string.length : 0) + 12 + 4 #hashstring + url length (shortened) + spaces
        @options[:status] = "#{quote_string(strip_string(@options[:title],max_length))} #{@options[:url]} #{hash_string}"
      end

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

    def options
      @options
    end

    def share_link(platform)
      share_options = SHARE_TEMPLATES[platform]
      params = options.keys & share_options[:params]
      if params.include?(:description) and !params.include?(:title)
        @options[:description] = @options[:title]
      end

      return share_options[:base]+params.collect{|k| "#{k}=#{url_encode(options[k])}"}.join('&')
    end
  end
end
