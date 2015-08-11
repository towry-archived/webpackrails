# encoding: utf-8

require 'tilt'
require 'open3'
require 'tempfile'
require 'fileutils'
require 'shellwords'

module WebpackRails
  class WebpackProcessor < Tilt::Template
    attr_accessor :config

    def initialize(template)
      self.config = Rails.application.config.webpack_rails
      super(template)
    end

    def prepare
      ensure_tmp_dir_exists!
      ensure_commands_exists!
      ensure_webpack_config_exists!
    end

    def evaluate(context, locals, &block)
      # return if there is nothing to do
      return data unless should_webpack?

      run_webpack(context.pathname || context.logical_path)
    end

    private 

    # Set the temp path
    def tmp_path
      @tmp_path ||= Rails.root.join('tmp', 'cache', 'webpack-rails').freeze
    end

    # return the webpack command path
    def webpack_cmd
      @webpack_cmd ||= rails_path(config.node_bin, "webpack").freeze
    end

    # make sure the temp dir exists
    def ensure_tmp_dir_exists!
      FileUtils.mkdir_p(rails_path(tmp_path))
    end

    # make sure the webpack config file exists
    def ensure_webpack_config_exists!
      @config_file ||= config.config_file

      if @config_file.blank?
        @config_file = Rails.root.join('webpack.config.js').freeze
      end

      if !File.exists?(@config_file)
        raise WebpackRails::WebpackError.new("Webpack config file not found.")
      end
    end

    # make sure the `webpack` command exists
    def ensure_commands_exists!
      error = ->(cmd) { "Unable to run #{cmd}. Ensure you have installed it with npm." }

      if !File.exists?(rails_path(webpack_cmd))
        raise WebpackRails::WebpackError.new(error.call(webpack_cmd))
      end
    end

    # should we use webpack to parse that file?
    def should_webpack?
      config.force || (in_path? && !webpacked? && commonjs_module?)
    end

    def in_path?
      config.paths.any? { |p| p === file  }
    end

    # Need check.
    def webpacked?
      data.to_s.include?("__webpack_require__")
    end
    
    def commonjs_module?
      data.to_s.include?("module.exports") || data.present? && data.to_s.include?("require") || data.present? && data.to_s.include?("import")
    end

    def asset_paths
      @asset_paths ||= Rails.application.config.assets.paths.collect { |p| p.to_s }.join(":") || ""
    end

    def env
      env_hash = {}
      env_hash["NODE_PATH"] = asset_paths unless uses_exorcist
      env_hash["NODE_ENV"] = config.node_env || Rails.env
      env_hash
    end

    def uses_exorcist
      false 
    end

    def run_webpack(logical_path=nil)
      command_options = "--colors --config #{@config_file} #{logical_path} --bail --output-filename"
      output_file = Tempfile.new("output", rails_path(tmp_path))
      command_options << " #{output_file.path.inspect}"

      command = "#{Shellwords.escape(webpack_cmd)} #{command_options}"

      base_directory = File.dirname(file)

      Logger::log "\nWebpack: #{command}"
      stdout, stderr, status = Open3.capture3(env, command, stdin_data: data, chdir: base_directory)

      if !status.success?
        raise WebpackRails::WebpackError.new("Error while running `#{command}`:\n\n#{stderr}")
      end

      output_file.read
    end

    def rails_path(*paths)
      Rails.root.join(*paths).to_s
    end
  end
end
