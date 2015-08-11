# encoding: utf-8

module WebpackRails
  class Railtie < Rails::Engine
    config.webpack_rails = ActiveSupport::OrderedOptions.new 

    # Webpack config file location
    config.webpack_rails.config_file = ''

    # Process every file?
    config.webpack_rails.force = false

    # paths to be parse
    config.webpack_rails.paths = [lambda { |p| p.start_with?(Rails.root.join("app").to_s) },
                                  lambda { |p| p.start_with?(Rails.root.join('node_modules').to_s) }]

    config.webpack_rails.node_bin = "node_modules/.bin/"

    initializer :setup_webpack do |app|
      app.assets.register_postprocessor "application/javascript", WebpackRails::WebpackProcessor
    end
  end
end
