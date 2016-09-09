module SocialLinker
  class Railtie < Rails::Railtie
    ActiveSupport.on_load(:action_view) do
      puts "Action view loaded, including SocialLinker::ViewHelpers"
      require 'social_linker/view_helpers'
      include SocialLinker::ViewHelpers
    end
  end
end