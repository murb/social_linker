require 'social_linker/view_helpers'
module SocialLinker
  class Railtie < Rails::Railtie
    ActiveSupport.on_load(:active_record) do
      include SocialLinker::ViewHelpers
    end
  end
end