# encoding: utf-8

module WebpackRails
  class Railtie < Rails::Engine
    config.webpackrails = ActiveSupport::OrderedOptions.new 

    # Webpack config file location
    config.webpackrails.config_file = ''

    # Process every file?
    config.webpackrails.force = false

    # paths to be parse
    config.webpackrails.paths = [lambda { |p| p.start_with?(Rails.root.join("app").to_s) },
                                  lambda { |p| p.start_with?(Rails.root.join('node_modules').to_s) }]

    config.webpackrails.node_bin = "node_modules/.bin/"

    # ignore node_modules
    config.webpackrails.ignore_node_modules = true

    # array of string to test if the file need to be process by this gem.
    # see `commonjs_module?` method
    config.webpackrails.force_condition = []

    initializer :setup_webpack do |app|
      app.assets.register_postprocessor "application/javascript", WebpackRails::WebpackProcessor
    end

    rake_tasks do 
      Dir[File.join(File.dirname(__FILE__), "tasks/*.rake")].each { |f| load f }
    end
  end
end
