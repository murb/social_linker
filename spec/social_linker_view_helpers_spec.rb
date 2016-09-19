require 'spec_helper'
$LOAD_PATH.unshift File.expand_path('../../app', __FILE__)
require 'helpers/view_helpers'

class SimulatedActionView
  include ViewHelpers
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
        expected_result = '<meta name="twitter:card" content="summary" />
<meta name="twitter:site" content="murb" />
<meta name="twitter:creator" content="murb" />
<meta name="twitter:domain" content="https://murb.nl" />
<meta property="og:url" content="https://murb.nl/blog" />
<link rel="canonical" content="https://murb.nl/blog" />
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
        expected_result = '<meta name="twitter:card" content="summary_large_image" />
<meta name="twitter:site" content="murb" />
<meta name="twitter:creator" content="murb" />
<meta name="twitter:domain" content="https://murb.nl" />
<meta property="og:url" content="https://murb.nl/blog" />
<link rel="canonical" content="https://murb.nl/blog" />
<meta name="keywords" content="key1 key2" />
<meta name="description" content="short summary" />
<meta name="twitter:description" content="short summary" />
<meta property="og:description" content="short summary" />
<meta name="twitter:image:src" content="https://murb.nl/image.jpg" />
<meta property="og:image" content="https://murb.nl/image.jpg" />
<meta property="og:image:type" content="image/jpeg" />
<title>title - murb.nl</title>
<meta name="twitter:title" content="title" />
<meta property="og:title" content="title" />'
        expect(SimulatedActionView.new.header_meta_tags(subject,options)).to eq(expected_result)

      end
    end

  end


end
