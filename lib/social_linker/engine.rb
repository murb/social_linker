module SocialLinker
  class Engine < ::Rails::Engine
    isolate_namespace SocialLinker
    config.to_prepare do
      ApplicationController.helper(ViewHelpers)
    end
  end
end