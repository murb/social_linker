require 'social_linker/view_helpers'
module SocialLinker
  class Railtie < Rails::Railtie
    initializer "social_linker.view_helpers" do
      ActionView::Base.send :include, ViewHelpers
    end
  end
end