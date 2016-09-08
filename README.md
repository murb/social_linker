# SocialLinker

SocialLinker is able to generate the most common share links for you, without depending on JavaScript. You should use generated links, instead of the share buttons provided by the platforms themselves, to protect your user's privacy, and this gem makes it easy for you to do so.

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

The supported options are:

* url
* media (media url, e.g. an image (now only Pinterest))
* summary
* description
* title
* tags

I've tried to map them as good as possible to the different share tools. Sometimes by combining several values. You may also pass along link-specific parameters such as `:hashtags`, so no 2-tag long string is generated from the list of tags.

To conclude: a very complete instantiation:

    @subject = SocialLinker::Subject.new(
      title: "title",
      url: "https://murb.nl/blog",
      image_url: "https://murb.nl/image.jpg",
      image_type: 'image/jpeg',
      summary: "short summary",
      tags: ["key1", "key2", "key3"],
      twitter_username: 'murb'
    )

## Rails helpers

When using Ruby on Rails a few helpers have been created.

### OpenGraph, Twitter, and HTML meta-data:

Just set the following, which should give you a reasonable default.

    header_meta_tags(@subject, {
      site_title_postfix: "your sitename" # optional
    })

### Share links

## TODO

* Render helpers (including SVG icons)
** later include even javascript timeout workarounds ( have to dive into http://stackoverflow.com/questions/7231085/how-to-fall-back-to-marketplace-when-android-custom-url-scheme-not-handled )
* Create a helper to render header meta tags with proper opengraph and twitter data
* Automatically add some basic utm tracking data to the urls https://support.google.com/analytics/answer/1033863?hl=en

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/murb/social_linker. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

