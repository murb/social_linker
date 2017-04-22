require 'spec_helper'
$LOAD_PATH.unshift File.expand_path('../../app', __FILE__)
require 'helpers/view_helpers'

class SimulatedActionView
  include ViewHelpers
  def capture
    yield
  end
end



describe SocialLinker do
  describe ViewHelpers do
    describe "#meta_tag" do
      it "should not render when content is empty" do
        expect(SimulatedActionView.new.meta_tag("a", nil)).to eq(nil)
      end
      it "should render when content is not empty" do
        expect(SimulatedActionView.new.meta_tag("a", "a")).to eq("<meta name=\"a\" content=\"a\" />")
      end
      it "should escape html content or names" do
        expect(SimulatedActionView.new.meta_tag("<script></script>", "<b></b>")).to eq("<meta name=\"&lt;script&gt;&lt;/script&gt;\" content=\"&lt;b&gt;&lt;/b&gt;\" />")
      end
      it "should render opengraph attributes as properties" do
        expect(SimulatedActionView.new.meta_tag("og:title", "rdf-a rules")).to eq("<meta property=\"og:title\" content=\"rdf-a rules\" />")
      end
    end

    describe "header_meta_tags" do
      it "should do basic tags when empty" do
        expect(SimulatedActionView.new.header_meta_tags(nil,{})).to eq("<title></title>")
        subject = SocialLinker::Subject.new
        expect(SimulatedActionView.new.header_meta_tags(subject,{})).to eq("<meta name=\"twitter:card\" content=\"summary\" />\n<title></title>")
        subject = SocialLinker::Subject.new(
          title: "title",
          url: "https://murb.nl/blog",
          summary: "short summary",
          tags: ["key1", "key2"],
          twitter_username: 'murb'
        )
        expected_result = '<meta name="twitter:site" content="murb" />
<meta name="twitter:creator" content="murb" />
<meta name="twitter:domain" content="https://murb.nl" />
<meta name="twitter:card" content="summary" />
<meta property="og:url" content="https://murb.nl/blog" />
<link rel="canonical" href="https://murb.nl/blog" />
<meta name="keywords" content="key1 key2" />
<meta name="description" content="short summary" />
<meta name="twitter:description" content="short summary" />
<meta property="og:description" content="short summary" />
<title>title</title>
<meta name="twitter:title" content="title" />
<meta property="og:title" content="title" />'
        expect(SimulatedActionView.new.header_meta_tags(subject,{})).to eq(expected_result)
        subject = SocialLinker::Subject.new(
          title: "title",
          url: "https://murb.nl/blog",
          image_url: "https://murb.nl/image.jpg",
          image_type: 'image/jpeg',
          summary: "short summary",
          tags: ["key1", "key2"],
          twitter_username: 'murb'
        )
        options = {
          site_title_postfix: "murb.nl"
        }
        expected_result = '<meta name="twitter:site" content="murb" />
<meta name="twitter:creator" content="murb" />
<meta name="twitter:domain" content="https://murb.nl" />
<meta name="twitter:card" content="summary_large_image" />
<meta property="og:url" content="https://murb.nl/blog" />
<link rel="canonical" href="https://murb.nl/blog" />
<meta name="keywords" content="key1 key2" />
<meta name="description" content="short summary" />
<meta name="twitter:description" content="short summary" />
<meta property="og:description" content="short summary" />
<meta name="twitter:image:src" content="https://murb.nl/image.jpg" />
<meta property="og:image" content="https://murb.nl/image.jpg" />
<meta property="og:image:type" content="image/jpeg" />
<title>title - murb.nl</title>
<meta name="twitter:title" content="title" />
<meta property="og:title" content="title" />
<meta property="og:site_name" content="murb.nl" />'
        expect(SimulatedActionView.new.header_meta_tags(subject,options)).to eq(expected_result)

      end
      it "should hide postprefix if set to do so" do
        subject = SocialLinker::Subject.new(
          title: "title",
          url: "https://murb.nl/blog",
          render_site_title_postfix: false
        )
        options = {
          site_title_postfix: "murb.nl"
        }
        expected_result = '<meta name="twitter:domain" content="https://murb.nl" />
<meta name="twitter:card" content="summary" />
<meta property="og:url" content="https://murb.nl/blog" />
<link rel="canonical" href="https://murb.nl/blog" />
<title>title</title>
<meta name="twitter:title" content="title" />
<meta property="og:title" content="title" />
<meta property="og:site_name" content="murb.nl" />'
        expect(SimulatedActionView.new.header_meta_tags(subject,options)).to eq(expected_result)
      end
      it "should be able to set title postfix if set to do so" do
        subject = SocialLinker::Subject.new(
          title: "title",
          site_title_postfix: "murb.nl",
          url: "https://murb.nl/blog",
        )
        expected_result = '<meta name="twitter:domain" content="https://murb.nl" />
<meta name="twitter:card" content="summary" />
<meta property="og:url" content="https://murb.nl/blog" />
<link rel="canonical" href="https://murb.nl/blog" />
<title>title - murb.nl</title>
<meta name="twitter:title" content="title" />
<meta property="og:title" content="title" />
<meta property="og:site_name" content="murb.nl" />'
        expect(SimulatedActionView.new.header_meta_tags(subject)).to eq(expected_result)
      end
    end
    describe "#social_link_to_image" do
      it "should return nil if no network or image path is given" do
        expect(SimulatedActionView.new.social_link_to_image(nil,nil)).to eq(nil)
      end
      it "should return an svg" do
        expect(SimulatedActionView.new.social_link_to_image(:facebook,"svg_path")).to eq("<svg class=\"icon icon-facebook icon-default-style\"><title>Facebook</title><use xlink:href=\"svg_path#icon-facebook\"></use></svg>")
      end
    end

    describe "#social_link_to" do
      it "should return an error when no subject is given" do
        expect{
          SimulatedActionView.new.social_link_to(nil,nil)
        }.to raise_error(ArgumentError)
      end
      it "should return an error when no network is given" do
        subject = SocialLinker::Subject.new(
          title: "title",
          url: "https://murb.nl/blog"
        )
        expect{
          SimulatedActionView.new.social_link_to(subject,nil)
        }.to raise_error(ArgumentError)
      end
      it "should return return a share link" do
        subject = SocialLinker::Subject.new(
          title: "title",
          url: "https://murb.nl/blog"
        )
        expect(SimulatedActionView.new.social_link_to(subject,:facebook)).to eq("<a href=\"https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fmurb.nl%2Fblog%3Futm_source%3Dfacebook%26utm_medium%3Dshare_link%26utm_campaign%3Dsocial\" target=\"_blank\" class=\"facebook\" title=\"Facebook\"><svg class=\"icon icon-facebook icon-default-style\"><title>Facebook</title><use xlink:href=\"social_linker/icons.svg#icon-facebook\"></use></svg></a>")
      end
      it "should return return a share link with a button class if given" do
        subject = SocialLinker::Subject.new(
          title: "title",
          url: "https://murb.nl/blog",
        )
        a = SimulatedActionView.new.social_link_to(subject,:facebook, {class: :button})
        expect(a).to eq("<a href=\"https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fmurb.nl%2Fblog%3Futm_source%3Dfacebook%26utm_medium%3Dshare_link%26utm_campaign%3Dsocial\" target=\"_blank\" class=\"button facebook\" title=\"Facebook\"><svg class=\"icon icon-facebook icon-default-style\"><title>Facebook</title><use xlink:href=\"social_linker/icons.svg#icon-facebook\"></use></svg></a>")
      end
      it "should return return a share link with a button classes if given" do
        subject = SocialLinker::Subject.new(
          title: "title",
          url: "https://murb.nl/blog",
        )
        a = SimulatedActionView.new.social_link_to(subject,:facebook, {class: [:button, :share]})
        expect(a).to eq("<a href=\"https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fmurb.nl%2Fblog%3Futm_source%3Dfacebook%26utm_medium%3Dshare_link%26utm_campaign%3Dsocial\" target=\"_blank\" class=\"button share facebook\" title=\"Facebook\"><svg class=\"icon icon-facebook icon-default-style\"><title>Facebook</title><use xlink:href=\"social_linker/icons.svg#icon-facebook\"></use></svg></a>")
      end
      it "should return return a share link when a block is given" do
        subject = SocialLinker::Subject.new(
          title: "title",
          url: "https://murb.nl/blog"
        )
        expect(SimulatedActionView.new.social_link_to(subject,:facebook){ "Facebook" }).to eq("<a href=\"https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fmurb.nl%2Fblog%3Futm_source%3Dfacebook%26utm_medium%3Dshare_link%26utm_campaign%3Dsocial\" target=\"_blank\" class=\"facebook\" title=\"Facebook\">Facebook</a>")
      end
      it "should return return a share link without target blank when told to do so" do
        subject = SocialLinker::Subject.new(
          title: "title",
          url: "https://murb.nl/blog"
        )
        expect(SimulatedActionView.new.social_link_to(subject,:facebook, {target_blank: false})).to eq("<a href=\"https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fmurb.nl%2Fblog%3Futm_source%3Dfacebook%26utm_medium%3Dshare_link%26utm_campaign%3Dsocial\" class=\"facebook\" title=\"Facebook\"><svg class=\"icon icon-facebook icon-default-style\"><title>Facebook</title><use xlink:href=\"social_linker/icons.svg#icon-facebook\"></use></svg></a>")
      end
    end
  end


end
