# frozen_string_literal: true

module ViewHelpers
  # renders a metatag
  # param [String, Symbol] name (or property) (defaults to name, values starting with 'og:' (opengraph) will be using the property attribute)
  # param [String, Symbol] content (the value for the name or the property)
  # @returns [String, nil] nil is returned when the content is empty
  def meta_tag(name, content)
    key_value_pairs = {}
    name_or_property_attribute = if name.start_with?("og:", "fb:")
      "property"
    elsif ["Content-Language"].include? name
      "http-equiv"
    else
      "name"
    end
    key_value_pairs[name_or_property_attribute] = name
    key_value_pairs[:content] = content
    tag_if(:meta, key_value_pairs, :content)
  end

  # renders a tag conditionally (if value is said)
  # param [String, Symbol] tagname of the tag
  # param [Hash] key value pairs (the attributes and their corresponding values
  # param [String, Symbol] if_key is the key to be checked for containing a value, otherwise nil is returned, defaults to :content
  # @returns [String, nil] nil is returned when the if_key is empty
  def tag_if(tagname, key_value_pairs, if_key = :content)
    tag = tagname.to_sym
    critical_value = key_value_pairs[if_key]
    if critical_value.to_s.strip != ""
      attribs = key_value_pairs.collect do |k, v|
        key = erb_sanitized(k)
        value = erb_sanitized(v)
        "#{key}=\"#{value}\""
      end.join(" ")
      "<#{tag} #{attribs} />"
    end
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
  # @param [Hash] options with site-defaults for `:site_title_postfix`, (e.g. article title - {site title postfix here}), `:domain` (the main url). These options are overridden by the subject if set by the subject.
  # @return String of tags (possibly marked as sanitized when available)
  def header_meta_tags subject, options = {}
    options = options.merge(subject.options) if subject

    site_title_postfix = options[:site_title_postfix]
    site_name = options[:site_name] || site_title_postfix
    site_title_postfix = nil if options[:render_site_title_postfix] == false
    language = options[:language]
    domain = options[:domain]

    header_html = []

    # <link href="https://plus.google.com/+YourPage" rel="publisher">
    #     <meta itemprop="name" content="Content Title">
    #     <meta itemprop="description" content="Content description less than 200 characters">
    #     <meta itemprop="image" content="http://example.com/image.jpg">
    # =

    header_html << meta_tag("twitter:site", options[:twitter_username])
    header_html << meta_tag("twitter:creator", options[:twitter_username])
    header_html << tag_if(:link, {href: "https://plus.google.com/+#{options[:google_plus_name]}", rel: "publisher"}, :href) if options[:google_plus_name]
    header_html << meta_tag("twitter:domain", domain)
    header_html << meta_tag("Content-Language", language)
    header_html << meta_tag("dc.language", language)
    header_html << meta_tag("og:locale", language)
    header_html << meta_tag("fb:app_id", options[:facebook_app_id])

    if subject
      header_html << meta_tag("twitter:card", subject.media ? :summary_large_image : :summary)

      if subject.url
        header_html << meta_tag("og:url", subject.canonical_url)
        header_html << "<link rel=\"canonical\" href=\"#{erb_sanitized(subject.canonical_url)}\" />"
      end

      header_html << meta_tag("keywords", subject.tags.join(" "))
      header_html << meta_tag("description", subject.summary(false))

      header_html << meta_tag("twitter:description", subject.summary(true))
      header_html << meta_tag("og:description", subject.summary(false))
      header_html << tag_if(:meta, {itemprop: :description, content: subject.summary(false)})

      if subject.media
        header_html << meta_tag("twitter:image:src", subject.media)
        header_html << meta_tag("og:image", subject.media)
        header_html << meta_tag("og:image:width", subject.media_width)
        header_html << meta_tag("og:image:height", subject.media_height)
        header_html << meta_tag("og:image:type", subject.image_type)
        header_html << tag_if(:meta, {itemprop: :image, content: subject.media})
      end
    end

    title = @title
    title = subject.title if subject
    site_title = [title, site_title_postfix].uniq.compact.join(" - ")
    header_html << "<title>#{erb_sanitized(site_title)}</title>"
    header_html << meta_tag("twitter:title", title)
    header_html << meta_tag("og:title", title)
    header_html << meta_tag("og:site_name", site_name)
    header_html << tag_if(:meta, {itemprop: :name, content: site_title}, :content)

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

  def social_link_to_image(network, image_path = nil)
    if image_path.nil?
      image_path = asset_path("social_linker/icons.svg") if methods.include?(:image_path)
    end

    if network && image_path
      "<svg class=\"icon icon-#{network} icon-default-style\"><title>#{network.capitalize}</title><use xlink:href=\"#{image_path}#icon-#{network}\"></use></svg>"
      # html = html.html_safe if html.methods.include?(:html_safe)

    end
  end

  # Generates the <a href> code for the subject and network
  # By default it will use the #social_link_to_image - function, refer to
  # that function if you don't see the icons rendered.
  #
  # Options:
  # @param [SocialLinker::Subject] the SocialLinker::Subject initialized as complete as possible
  # @param [Symbol] network key (e.g. twitter, facebook, see README and/or SocialLinker::Subject::SHARE_TEMPLATES )
  # params [Hash] options:
  #  * :social_icons_image_path (defaults to the default SocialLinker iconset)
  #  * :title (the title attribute, defaults to the network's name capitalized)
  #  * :target_blank (boolean whether it should open in a new window)
  #  * :class (array or string of classes to add to the a-href element)
  # @return String of html (possibly marked as sanitized when available)

  def social_link_to subject, network, options = {}
    raise ArgumentError, "subject can't be nil" unless subject
    raise ArgumentError, "network can't be nil" unless network
    options_with_defaults = {
      social_icons_asset_path: "social_linker/icons.svg",
      title: network.to_s.capitalize,
      target_blank: true
    }.merge(options)

    link_content = network

    if block_given?
      link_content = capture { yield }
    else
      social_icons_asset_path = options_with_defaults[:social_icons_asset_path]
      social_icons_asset_path = asset_path(social_icons_asset_path) if methods.include?(:image_path)

      link_content = social_link_to_image(network, social_icons_asset_path)
    end

    title = options_with_defaults[:title]
    html_class = [options_with_defaults[:class], network].flatten.compact.join(" ")
    targetblank = options_with_defaults[:target_blank] ? " target=\"_blank\"" : ""
    html = "<a href=\"#{erb_sanitized(subject.share_link(network))}\"#{targetblank} class=\"#{html_class}\" title=\"#{title}\">#{link_content}</a>"
    html = html.html_safe if html.methods.include?(:html_safe)
    html
  end
end
