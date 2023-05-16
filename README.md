# SocialLinker

[![Build Status](https://travis-ci.org/murb/social_linker.svg?branch=master)](https://travis-ci.org/murb/social_linker)

**SocialLinker solves two problems involving social networks (and search engines):
proper meta-headers and proper share links.**

SocialLinker is able to generate the most common share links for you, without depending on JavaScript.
You should use generated links, instead of the share buttons provided by the platforms themselves, to
protect your user's privacy, and this gem makes it easy for you to do so.

And when using Rails, SocialLinker also solves the tedious job of getting the meta tags right.
Because once you've set the SocialLinker::Subject correctly, you've also got the right ingredients
for the perfect meta keywords & description, open graph variables etc.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'social_linker'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install social_linker

## Usage

### Basics

Initialize the subject with enough material to generate links from, such as the page's url, maybe the image url (mainly for Pinterest type-shares), a description, tags etc.

For example, initialze

```ruby
social_linker_subject = SocialLinker::Subject.new(media: "http://example.com/img.jpg", url: "http://example.com/", title: "Example website", description: "Example.com is the typical URL you would want to use in explanations anyway."
```

You'll get the e-mail share url by calling:

```ruby
social_linker_subject.share_link(:mail)
```

Which will deliver you the following url:

    mailto:emailaddress?subject=Example%20website&body=Example.com%20is%20the%20typical%20URL%20you%20would%20want%20to%20use%20in%20explanations%20anyway.%0A%0Ahttp%3A%2F%2Fexample.com%2F

### Setting up the subject

The supported options are:

* url
* media (media url, e.g. an image (shared only for Pinterest, but also used in OpenGraph headers & Twitter Cards))
* summary
* description
* title
* tags

And of a more site-global nature:

* twitter_username
* facebook_app_id
* language
* site_title_postfix (which can be hidden by setting `render_site_title_postfix` to false)

I've tried to map them as good as possible to the different share tools. Sometimes by combining several values. You may also pass along link-specific parameters such as `:hashtags`, so you can control the 2-tag long string that is generated from the list of tags by default.

For example:

    @subject = SocialLinker::Subject.new(
      title: "title",
      url: "https://murb.nl/blog",
      media: "https://murb.nl/image.jpg",
      media_dimensions: [640, 480],
      summary: "short summary",
      tags: ["key1", "key2", "key3"],
    )

You can also merge details later on. Let's say you want to set the global values:

    @subject = SocialLinker::Subject.new(
      site_title_postfix: ":murb:",
      twitter_username: 'murb',
      facebook_app_id: '123123123',
      tags: ['murb', 'ruby']
    )

You might to set these defaults in a before action in your (Ruby on Rails-speak)
ApplicationController. Later on you can merge details into this subject:

    @subject.merge!({
      title: "title",
      url: "https://murb.nl/blog",
      media: "https://murb.nl/image.jpg",
      media_dimensions: [640, 480],
      summary: "short summary",
      tags: ["key1", "key2", "key3"]
    })

*Hint*, the media_dimensions are 'compatible' with the output of the Dimensions-gem:

    @subject.merge!({
      title: @article.title,
      url: article_url(@article),
      media: @article.image.url(:inline),
      media_dimensions: Dimensions.dimensions(@article.image.path(:inline)),
      summary: @article.description,
      tags: @article.tag_list.to_a
    })


### Creating share links


Currently support is available for the following ways of sharing:

    :email
    :facebook
    :facebook_native
    :twitter
    :twitter_native
    :pinterest
    :google
    :linkedin
    :whatsapp

Or to save you the copy-paste:

[TestMailLink](mailto:emailaddress?subject=Example%20website&body=Example.com%20is%20the%20typical%20URL%20you%20would%20want%20to%20use%20in%20explanations%20anyway.%0A%0Ahttp%3A%2F%2Fexample.com%2F)


#### UTM Campaign parameters

By default [utm campaign parameters](https://support.google.com/analytics/answer/1033863?hl=en) are added when they are not present. You can turn this off by passing the option: `utm_parameters: false`.

#### Link helper with SVG icons (Rails)

Use the following to create a sharelink to Facebook

    social_link_to @subject, :facebook

This results in a simple `<a href>` containing the share link and an svg image.
This SVG image may or may not be found depending on your asset initialization,
make sure that config/initializers/assets.rb contains the following line:

    Rails.application.config.assets.precompile += %w( social_linker/icons.svg )

(if you don't it probably will be suggested to you by Rails)

If you want to change the content of the link, pass a block, e.g.:

    social_link_to @subject, :facebook do
      "Share on Facebook!"
    end

To make sure that the icons align well, make sure to include the styling, include
the following line to the head of your application.ccs file:

    *= require social_linker/icons


### Meta-Headers

When using Ruby on Rails a few helpers have been created.


Just set the following, which should give you a reasonable default.

    header_meta_tags(@subject, {
      site_title_postfix: "your sitename" # optional
    })

Alternatively you can also set the `site_title_post` in the `Subject` directly,
as suggested in an earlier section:

    header_meta_tags(@subject)

## Advanced

### Reuse the SVG icons elsewhere

When integrating social icons into your site, you might also want to include login options
for these social networks, or access the icons for other reasons. Below is 'standard'
example code of how to access image-assets in the icon

    <svg class="icon icon-facebook-official">
      <use xlink:href="<%=image_path('social_linker/icons.svg')%>#icon-facebook"></use>
    </svg>

When the `assets/config/manifest.js` file is present, you have to include it:

    //= link social_linker/icons.svg

Previous versions required you to add the icons.svg tot the assets initializers

     Rails.application.config.assets.precompile += %w( images/social_linker/icons.svg )

*Note:* If you just want the SVG icon standalone, you can also use the `social_link_to_image`
view helper:

    social_link_to_image :facebook

Included layers:

* icon-email
* icon-google
* icon-sticky-note-o
* icon-share-square-o
* icon-search
* icon-heart-o
* icon-heart
* icon-twitter
* icon-pinterest
* icon-facebook
* icon-facebook-unofficial
* icon-linkedin
* icon-whatsapp
* icon-tumblr

Icons have been created with the [IcoMoon App](https://icomoon.io/app) and come
from the [Font Awesome](http://scripts.sil.org/OFL)-set (OFL licensed).

## Problem solving

### SVG Icons not showing up in older browsers

When using SVG and serving your pages to older browsers, make sure you use something
like SVG4Everyone. Include in your gemfile:

    source 'https://rails-assets.org' do
     gem 'rails-assets-svg4everybody'
    end

and include the following line to the head of your `application.js` file:

    //= require svg4everybody


## TODO

* Idea: maybe improve share helpers with [javascript timeout workarounds](http://stackoverflow.com/questions/7231085/how-to-fall-back-to-marketplace-when-android-custom-url-scheme-not-handled) for native alternatives (although Twitter and facebook work well)
* More share methods (pull request welcome)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/murb/social_linker. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

