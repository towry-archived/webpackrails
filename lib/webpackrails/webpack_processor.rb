# encoding: utf-8

require 'tilt'
require 'open3'
require 'tempfile'
require 'fileutils'
require 'shellwords'
require 'digest/sha1'

module WebpackRails
  class WebpackProcessor < Tilt::Template
    attr_accessor :config

    def initialize(template)
      self.config = Rails.application.config.webpackrails
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

      if config.embed_erb
        run_webpack(context.pathname || context.logical_path, false)

        evaluate_dependencies(context.environment.paths).each do |path|
          context.depend_on(path.to_s)
        end

        if !@erb_deps.empty?
          evaluate_erb_deps(context, locals)
        end

        evaluated = run_webpack(context.pathname || context.logical_path)
      else
        evaluated = run_webpack(context.pathname || context.logical_path)
        evaluate_dependencies(context.environment.paths).each do |path|
          context.depend_on(path.to_s)
        end
      end
      
      evaluated
    end

    private 

    def evaluate_erb_deps(context, locals)
      return if @erb_deps.empty?

      # dep is a path
      @erb_deps.each do |dep|
        begin 
          shaname = sha1(dep)
          tmpfile = File.join(@erb_deps_root, shaname)
          template = Tilt::ERBTemplate.new(dep)
          template = template.render(context, locals)
          file = File.open(tmpfile, 'w')
          file.write(template)
          file.close()
        end
      end
    end

    def sha1(content)
      Digest::SHA1.hexdigest content
    end

    # Set the temp path
    def tmp_path
      @tmp_path ||= Rails.root.join('tmp', 'cache', 'webpackrails').freeze
    end

    # return the webpack command path
    def webpack_cmd
      @webpack_cmd ||= rails_path(config.node_bin, "webpack").freeze
    end

    # make sure the temp dir exists
    def ensure_tmp_dir_exists!
      FileUtils.mkdir_p(rails_path(tmp_path))
      @deps_path ||= File.join(tmp_path, '_$webpackrails_dependencies');
      @erb_deps_root ||= rails_path('tmp/cache/webpackrails/erbs').freeze

      FileUtils.mkdir_p(@erb_deps_root)
    end

    # Filter out node_module/ files and erb files.
    def evaluate_dependencies(asset_paths) 
      return dependencies if !config.ignore_node_modules and !config.embed_erb

      @erb_deps = []
      deps = dependencies.select do |path|
        if File.extname(path) == '.erb'
          @erb_deps << path 
        end
        path.start_with?(*asset_paths)
      end
    end

    # return array
    def dependencies
      ret ||= begin
        if !File.exists?(@deps_path)
          return []
        end

        output = ''
        begin
          file = File.open(@deps_path, 'r')
          output = file.read
          file.close
        rescue
          output = ''
        end

        if !output
          return []
        end

        output.lines.map(&:strip).select do |path|
          File.exists?(path)
        end
      end
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
      return false if !data.present?

      condition = ["module.exports", "require", "import", "export", "exports", "export default", "React"]
      data_s = data.to_s

      (condition + config.force_condition).uniq.any? { |c| data_s.include?(c) }
    end

    def asset_paths
      @asset_paths ||= Rails.application.config.assets.paths.collect { |p| p.to_s }.join(":") || ""
    end

    def env
      env_hash = {}
      env_hash["NODE_PATH"] = asset_paths unless uses_exorcist
      env_hash["NODE_ENV"] = config.node_env || Rails.env
      env_hash["WR_TMP_FILE"] = @deps_path;
      env_hash['RAILS_ROOT'] = Rails.root.to_s
      env_hash
    end

    # Not supported yet.
    def uses_exorcist
      false 
    end

    def run_webpack(logical_path=nil, bail= true)
      if bail
        command_options = "--colors --config #{@config_file} #{logical_path} --bail --output-filename"
      else 
        command_options = "--colors --config #{@config_file} #{logical_path} --output-filename"
      end
      
      output_file = Tempfile.new("output", rails_path(tmp_path))
      command_options << " #{output_file.path.inspect}"

      command = "#{Shellwords.escape(webpack_cmd)} #{command_options}"

      base_directory = File.dirname(file)

      Logger::log "\nWebpack: #{command}"

      mut_env = ENV.to_hash
      mut_env.merge!(env)
      ENV.replace(mut_env)
      stdout, stderr, status = Open3.capture3(env, command, stdin_data: data, chdir: base_directory)

      if !status.success?
        raise WebpackRails::WebpackError.new("Error while running `#{command}`:\n\n#{stderr}")
      end

      output = output_file.read

      output_file.close 
      output_file.unlink

      output
    end

    def rails_path(*paths)
      Rails.root.join(*paths).to_s
    end
  end
end
