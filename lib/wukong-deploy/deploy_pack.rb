module Wukong
  module Deploy
    
    # Return the root directory of this deploy pack.
    #
    # @return [Pathname]
    def self.root
      @root
    end
    
    # Recursively require each Ruby file +dir+.
    #
    # @example Requiring all .rb files anywhere within /lib/my_lib
    #
    #   Wukong::Deploy.require_recursive("lib/my_lib")
    #
    # @param [String] glob
    def self.require_recursive glob, ext='.rb'
      Dir[root.join("#{glob}/**/*#{ext}")].each { |path| require(path) }
    end

    # Return the current environment the deploy pack is in.
    #
    # @return [String]
    def self.environment
      settings[:environment]
    end

    # Return the deploy pack's own settings.
    #
    # @return [Configliere::Param]
    def self.settings
      @settings
    end

    # Return the settings the deploy pack had *before* it booted
    # itself -- these are used to pass to other tools when invoking
    # them, since they will read the deploy pack settings themselves
    # anyway.
    #
    # @return [Configliere::Param]
    def self.pre_deploy_settings
      @pre_deploy_settings
    end

    # The root directory of this deploy pack.
    #
    # @return [Pathname]
    def self.root
      @root
    end

    # The directory this deploy pack keeps local, sample data in.
    #
    # @return [Pathname]
    def self.data_dir
      root.join('data')
    end

    # The directory this deploy pack uses for configuration files.
    #
    # @return [Pathname]
    def self.config_dir
      root.join('config')
    end

    # The directory this deploy pack uses for temporary files.
    #
    # @return [Pathname]
    def self.tmp_dir
      root.join('tmp')
    end

    # The directory this deploy pack uses for logs.
    #
    # @return [Pathname]
    def self.log_dir
      root.join('log')
    end

    # The diretory this deploy pack puts all its application code in.
    #
    # @return [Pathname]
    def self.app_dir
      root.join('app')
    end
    
    private

    # Read settings common across all environments from
    # `config/settings.yml`.
    #
    # Will also read any YAML files in the `config/settings` directory
    # -- order is *not* guaranteed.
    def self.read_common_settings
      read_settings_from_file(settings, config_dir.join("settings.yml"))
      if File.directory?(config_dir.join('settings'))
        Dir[config_dir.join('settings','*.yml')].each do |path|
          read_settings_from_file(settings, path)
        end
      end
    end
    
    # Read settings unique to this deploy pack's current environment
    # from config/environments/ENVIRONMENT.yml.
    #
    # Will also read any YAML files in the
    # `config/environments/ENVIRONMENT` directory -- order is *not*
    # guaranteed.
    def self.read_environment_settings
      read_settings_from_file(settings, config_dir.join("environments", "#{environment}.yml"))
      if File.directory?(config_dir.join('environments', environment))
        Dir[config_dir.join('environments', environment, '*.yml')].each do |path|
          read_settings_from_file(settings, path)
        end
      end
    end

    # Read settings created by a deployment tool from
    # `config/deploy.yml` and
    # `config/environments/deploy-ENVIRONMENT.yml.
    def self.read_deploy_settings
      # pass 'false' here so we don't log an annoying warning message
      # when not in a deployed environment.
      read_settings_from_file(settings, config_dir.join("deploy.yml"),                                false)
      read_settings_from_file(settings, config_dir.join("environments", "deploy-#{environment}.yml"), false)
    end

    # Update +settings+ with the configuration at the given +path+.
    #
    # @param [Configliere::Param] settings
    # @param [String, Pathname] path
    # @param [true, false] warn whether to log a warning message if no config file is found
    def self.read_settings_from_file settings, path, warn=true
      if File.exist?(path) && File.readable?(path) && File.file?(path)
        settings.read(path)
      else
        Wukong::Log.warn("Could not read settings from path: #{path}") if warn
      end
    end

    # Read remote settings.
    #
    # FIXME -- not implemented yet.
    def self.read_remote_settings
    end
  end
end
