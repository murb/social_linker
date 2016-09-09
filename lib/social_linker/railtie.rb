module SocialLinker
  class Railtie < Rails::Railtie
    ActiveSupport.on_load(:action_view) do
      require 'social_linker/view_helpers'
      include SocialLinker::ViewHelpers
    end
  end
end