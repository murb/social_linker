require 'spec_helper'

describe SocialLinker do
  it 'has a version number' do
    expect(SocialLinker::VERSION).not_to be nil
  end

  it 'can be initialized' do
    expect(SocialLinker::Subject.new.class).to eq(SocialLinker::Subject)
  end

  describe '#strip_string' do
    it "doesn't shorten short enough strings" do
      slb = SocialLinker::Subject.new
      expect(slb.strip_string("abc", 3)).to eq("abc")
    end
    it "shortens too long strings" do
      slb = SocialLinker::Subject.new
      expect(slb.strip_string("abcd", 3)).to eq("ab…")
    end
    it "shortens quotes nicely" do
      slb = SocialLinker::Subject.new
      expect(slb.strip_string("“abcdefg”", 5)).to eq("“ab…”")
    end
  end

  describe '#hashtag_string' do
    it 'returns nill if no hashes are given' do
      slb = SocialLinker::Subject.new
      expect(slb.hashtag_string([])).to eq(nil)
    end
    it 'accepts array of strings' do
      slb = SocialLinker::Subject.new
      expect(slb.hashtag_string(["a", "b"])).to eq("#a #b")
      expect(slb.hashtag_string(["#a", "#b"])).to eq("#a #b")
    end
    it 'accepts symbols' do
      slb = SocialLinker::Subject.new
      expect(slb.hashtag_string([:a, :b])).to eq("#a #b")
    end
    it 'deals with spaces in tags' do
      slb = SocialLinker::Subject.new
      expect(slb.hashtag_string(["abc alphabet", "b"])).to eq("#AbcAlphabet #b")
      expect(slb.hashtag_string(["#a", "#b"])).to eq("#a #b")
    end
  end

  describe '#quote_string' do
    it 'should quote a string' do
      slb = SocialLinker::Subject.new
      expect(slb.quote_string("aa")).to eq("“aa”")
    end
    it 'should return nil if no string' do
      slb = SocialLinker::Subject.new
      expect(slb.quote_string(nil)).to eq(nil)
    end
  end

  describe '#camelize_tag_when_needed' do
    it 'should not camelize single words' do
      slb = SocialLinker::Subject.new
      expect(slb.camelize_tag_when_needed("aaaa")).to eq("aaaa")
    end
    it 'should  camelize two words' do
      slb = SocialLinker::Subject.new
      expect(slb.camelize_tag_when_needed("aaaa bbb")).to eq("AaaaBbb")
    end
  end

  describe '#initialize' do
    it 'generates nice defaults' do
      slb = SocialLinker::Subject.new(url: "http://example.com")
      expect(slb.options[:u]).to eq("http://example.com")
      expect(slb.status).to eq("http://example.com?utm_source=<%=share_source%>&utm_medium=share_link&utm_campaign=social")
    end
  end

  describe "#prefix_domain" do
    before(:example) do
      @slb = SocialLinker::Subject.new
    end

    it 'should not touch full urls' do
      expect(@slb.prefix_domain("http://example.com/image.jpg", "https://example.com")).to eq("http://example.com/image.jpg")
    end

    it 'should not not generate double slashes' do
      expect(@slb.prefix_domain("/image.jpg", "https://example.com/")).to eq("https://example.com/image.jpg")
    end

    it 'should add slash when needed' do
      expect(@slb.prefix_domain("image.jpg", "https://example.com")).to eq("https://example.com/image.jpg")
    end
  end

  describe '#share_link' do
    # mailto:sadf?&subject=Interessant&body=http%3A//example.com
    # https://pinterest.com/pin/create/button/?url=http%3A//example.com&media=http%3A//sharelinkgenerator.com/share-link-generator-logo.png&description=test
    # https://www.linkedin.com/shareArticle?mini=true&url=http%3A//example.com&title=title&summary=summary&source=http%3A//example.com
    # https://plus.google.com/share?url=http%3A//example.com
    # https://twitter.com/home?status=http%3A//example.com
    it 'should urlencode values' do
      slb = SocialLinker::Subject.new(url: "http://example.com")
      expect(slb.share_link(:facebook)).to eq("https://www.facebook.com/sharer/sharer.php?u=http%3A%2F%2Fexample.com")
    end


    describe 'platforms' do
      it 'should work for :facebook' do
        # https://www.facebook.com/sharer/sharer.php?u=http%3A//example.com
        slb = SocialLinker::Subject.new(url: "http://example.com")
        expect(slb.share_link(:facebook)).to eq("https://www.facebook.com/sharer/sharer.php?u=http%3A%2F%2Fexample.com")
      end
      it 'should work for :twitter' do
        # https://www.facebook.com/sharer/sharer.php?u=http%3A//example.com
        slb = SocialLinker::Subject.new(url: "https://murb.nl")
        expect(slb.share_link(:twitter)).to eq("https://twitter.com/intent/tweet?url=https%3A%2F%2Fmurb.nl%3Futm_source%3Dtwitter%26utm_medium%3Dshare_link%26utm_campaign%3Dsocial")
        slb = SocialLinker::Subject.new(url: "https://murb.nl", title: "Mooi recept")
        expect(slb.share_link(:twitter)).to eq("https://twitter.com/intent/tweet?text=%E2%80%9CMooi%20recept%E2%80%9D&url=https%3A%2F%2Fmurb.nl%3Futm_source%3Dtwitter%26utm_medium%3Dshare_link%26utm_campaign%3Dsocial")
        slb = SocialLinker::Subject.new(url: "https://murb.nl", title: "Well done", tags: [:recept], email: "github@murb.nl", utm_parameters: false)
        expect(slb.share_link(:twitter)).to eq("https://twitter.com/intent/tweet?text=%E2%80%9CWell%20done%E2%80%9D&url=https%3A%2F%2Fmurb.nl&hashtags=recept")
      end
      it 'should work for :email' do
        slb = SocialLinker::Subject.new(url: "http://example.com", title: "Mooi recept", description: "Met een heerlijke saus!")
        expect(slb.share_link(:email)).to eq("mailto:emailaddress?subject=Mooi%20recept&body=Met%20een%20heerlijke%20saus%21%0A%0Ahttp%3A%2F%2Fexample.com%3Futm_source%3Demail%26utm_medium%3Dshare_link%26utm_campaign%3Dsocial")
        social_linker_subject = SocialLinker::Subject.new(media: "http://example.com/img.jpg", url: "http://example.com/", title: "Example website", description: "Example.com description", utm_parameters: false)
        expect(social_linker_subject.share_link(:email)).to eq("mailto:emailaddress?subject=Example%20website&body=Example.com%20description%0A%0Ahttp%3A%2F%2Fexample.com%2F%0A%0Ahttp%3A%2F%2Fexample.com%2Fimg.jpg")

      end
      it 'should work for :pinterest' do
        slb = SocialLinker::Subject.new(media: "img", url: "http://example.com", title: "Mooi recept", description: "Met een heerlijke saus!")
        expect(slb.share_link(:pinterest)).to eq("https://pinterest.com/pin/create/button/?url=http%3A%2F%2Fexample.com%3Futm_source%3Dpinterest%26utm_medium%3Dshare_link%26utm_campaign%3Dsocial&media=http%3A%2F%2Fexample.com%2Fimg&description=Mooi%20recept")
      end
      it 'should work for :google' do
        slb = SocialLinker::Subject.new(media: "img", url: "http://example.com", title: "Mooi recept", description: "Met een heerlijke saus!")
        expect(slb.share_link(:google)).to eq("https://plus.google.com/share?url=http%3A%2F%2Fexample.com%3Futm_source%3Dgoogle%26utm_medium%3Dshare_link%26utm_campaign%3Dsocial")
      end

    end
  end

  describe '#method_missing' do
    describe 'but looks like a share method' do
      it 'should generate a share link' do
        slb = SocialLinker::Subject.new(url: "http://example.com")
        expect(slb.twitter_share_link).to eq("https://twitter.com/intent/tweet?url=http%3A%2F%2Fexample.com%3Futm_source%3Dtwitter%26utm_medium%3Dshare_link%26utm_campaign%3Dsocial")
      end
    end
    describe 'might be an option value' do
      it 'should return the option value if it is an option value' do
        slb = SocialLinker::Subject.new(curl: "http://example.com")
        expect(slb.curl).to eq("http://example.com")
      end
      it 'should raise NoMethodError when it is not an option value (and not a share link)' do
        slb = SocialLinker::Subject.new(curl: "http://example.com")
        expect{slb.cfurl}.to raise_error(NoMethodError)
      end
    end
  end

  describe "#description" do
    it "should return description" do
      slb = SocialLinker::Subject.new(description: "abc", url: "http://g.to")
      expect(slb.description).to eq("abc")
    end
    it "should return description" do
      long_string = 100.times.collect{|a| "abcd a"}.join("")
      slb = SocialLinker::Subject.new(description: long_string, url: "http://g.to")
      expect(slb.description).to eq(long_string)
    end

  end

  describe "#summary" do
    it "should return description" do
      long_string = 100.times.collect{|a| "abcd a"}.join("")
      slb = SocialLinker::Subject.new(description: long_string, url: "http://g.to")
      expect(slb.summary).to eq(long_string)
    end
    it "should return description" do
      long_string = 100.times.collect{|a| "abcd a"}.join("")
      slb = SocialLinker::Subject.new(description: long_string, url: "http://g.to")
      expect(slb.summary(true)).to eq("abcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd aabcd …")
    end
  end

  describe "#merge!" do
    it "should allow an empty set of values to be merged" do
      slb = SocialLinker::Subject.new(url: "http://g.to", message: "kaas")
      slb.merge!({})
      expect(slb.message).to eq("kaas")
    end
    it "should allow values to be overwritten" do
      slb = SocialLinker::Subject.new(url: "http://g.to", message: "kaas")
      slb.merge!({message: "cheese"})
      expect(slb.message).to eq("cheese")
    end
    it "allows merging with another sociallinker subject" do
      slb = SocialLinker::Subject.new(url: "http://g.to", message: "kaas")
      slb.merge!(SocialLinker::Subject.new(message: "cheese"))
      expect(slb.message).to eq("cheese")
    end
  end


end
