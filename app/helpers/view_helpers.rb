module ViewHelpers
  # renders a metatag
  # param [String, Symbol] name (or property) (defaults to name, values starting with 'og:' (opengraph) will be using the property attribute)
  # param [String, Symbol] content (the value for the name or the property)
  # @returns [String, nil] nil is returned when the content is empty
  def meta_tag(name, content)
    name_or_property_section = name.start_with?("og:") ? "property=\"#{erb_sanitized(name)}\"" : "name=\"#{erb_sanitized(name)}\""
    "<meta #{name_or_property_section} content=\"#{erb_sanitized(content)}\" />" if content and content != ""
  end

  def erb_sanitized(value)
    if defined? Rails
      h(value)
    else
      ERB::Util.h(value)
    end
  end

  # header_meta_tags renders the most important metatags based on the SocialLinker::Subject
  #
  # @param [SocialLinker::Subject] the SocialLinker::Subject initialized as complete as possible
  # @param [Hash] options with site-defaults for `:site_title_postfix`, (e.g. article title - {site title postfix here}), `:domain` (the main url),
  # @return String of tags (possibly marked as sanitized when available)
  def header_meta_tags subject, options={}
    site_title_postfix = options[:site_title_postfix]
    header_html = []
    if subject
      domain = options[:domain] || subject.options[:domain]

      header_html << meta_tag("twitter:card", subject.media ? :summary_large_image : :summary)
      header_html << meta_tag("twitter:site", subject.options[:twitter_username])
      header_html << meta_tag("twitter:creator", subject.options[:twitter_username])
      header_html << meta_tag("twitter:domain", domain)

      if subject.url
        header_html << meta_tag("og:url", subject.canonical_url)
        header_html << "<link rel=\"canonical\" href=\"#{erb_sanitized(subject.canonical_url)}\" />"
      end

      header_html << meta_tag("keywords", subject.tags.join(" "))
      header_html << meta_tag("description", subject.summary(true))

      header_html << meta_tag("twitter:description", subject.summary(true))
      header_html << meta_tag("og:description", subject.summary(true))

      if subject.media
        header_html << meta_tag("twitter:image:src", subject.media)
        header_html << meta_tag("og:image", subject.media)
        header_html << meta_tag("og:image:type", subject.options[:image_type])
      end
    end

    title = @title
    title = subject.title if subject
    site_title = [title, site_title_postfix].uniq.compact.join(" - ")
    header_html << "<title>#{erb_sanitized(site_title)}</title>"
    header_html << meta_tag("twitter:title", title)
    header_html << meta_tag("og:title", title)

    header_html.compact!
    header_html = header_html.join("\n") if header_html

    # we trust the html because all user input is sanitized by erb_sanitized
    header_html = header_html.html_safe if header_html.methods.include?(:html_safe)
    header_html
  end

  # Generates the <SVG> code for the image
  # It references the parent image path with `xlink:href`. Make sure your browser supports this, or use something like `svg4everyone` to fix your client's browsers
  # Options:
  # * social_icons_image_path (defaults to the default SocialLinker iconset)
  # * title (the title attribute, defaults to the network's name capitalized)

  def social_link_to_image(network, image_path)
    if network and image_path
      "<svg class=\"icon icon-#{network} icon-default-style\"><use xlink:href=\"#{image_path}#icon-#{network}\"></use></svg>"
    end
  end

  def social_link_to subject, network, options = {}
    raise ArgumentError, "subject can't be nil" unless subject
    raise ArgumentError, "network can't be nil" unless network
    options_with_defaults = {
      social_icons_image_path: 'social_linker/icons.svg',
      title: network.to_s.capitalize
    }.merge(options)

    link_content = network

    if block_given?
      link_content = yield
    else
      social_icons_image_path = options_with_defaults[:social_icons_image_path]
      social_icons_image_path = image_path(social_icons_image_path) if self.methods.include?(:image_path)

      link_content = social_link_to_image(network, social_icons_image_path)
    end

    title = options_with_defaults[:title]

    html = "<a href=\"#{erb_sanitized(subject.share_link(network))}\" class=\"#{network}\" title=\"#{title}\">#{link_content}</a>"
    html = html.html_safe if html.methods.include?(:html_safe)
    html
  end

end
