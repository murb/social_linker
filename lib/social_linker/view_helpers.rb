module SocialLinker
  module ViewHelpers
    # renders a metatag
    # param [String, Symbol] name (or property) (defaults to name, values starting with 'og:' (opengraph) will be using the property attribute)
    # param [String, Symbol] content (the value for the name or the property)
    # @returns [String, nil] nil is returned when the content is empty
    def meta_tag(name, content)
      name_or_property_section = name.start_with?("og:") ? "property=\"#{h(name)}\"" : "name=\"#{h(name)}\""
      "<meta #{name_or_property_section} content=\"#{h(content)}\" />" if content and content != ""
    end

    # render_social_linker_header_tags renders the most important metatags based on the SocialLinker::Subject
    # param [SocialLinker::Subject] the SocialLinker::Subject initialized as complete as possible
    # param [Hash] options with site-defaults for `:site_title_postfix`, (e.g. article title - {site title postfix here}), `:domain` (the main url), `
    def render_social_linker_header_tags subject, options={}
      site_title_postfix = options[:site_title_postfix]
      header_html = []
      if subject
        domain = options[:domain] || subject.options[:domain]

        header_html << meta_tag("twitter:card", :summary)
        header_html << meta_tag("twitter:site", subject.options[:twitter_username])
        header_html << meta_tag("twitter:creator", subject.options[:twitter_username])
        header_html << meta_tag("twitter:domain", domain)

        if subject.url
          header_html << meta_tag("og:url", subject.url)
          header_html << "<link rel=\"canonical\" content=\"#{h(subject.url)}\" />"
        end

        header_html << meta_tag("keywords", subject.tags.join(" "))
        header_html << meta_tag("description", subject.summary)

        header_html << meta_tag("twitter:description", subject.summary)
        header_html << meta_tag("og:description", subject.summary)

        if subject.media
          header_html << meta_tag("twitter:image:src", subject.media)
          header_html << meta_tag("og:image", subject.media)
          header_html << meta_tag("og:image:type", subject.options[:image_type])
        end
      end

      title = @title
      title = subject.title if subject
      site_title = [title, site_title_postfix].uniq.compact.join(" - ")
      header_html << "<title>#{site_title}</title>"
      header_html << meta_tag("twitter:title", title)
      header_html << meta_tag("og:title", title)

      header_html.compact!
      header_html.join("\n") if header_html

    end

  end
end
