module Strainer
  # The Runner class is responsible for executing the tests against cookbooks.
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  class Runner
    # List taken from: http://wiki.opscode.com/display/chef/Chef+Configuration+Settings
    # Listed in order of preferred preference
    KNIFE_LOCATIONS = [
      './.chef/knife.rb',
      '~/.chef/knife.rb',
      '/etc/chef/solo.rb',
      '/etc/chef/client.rb'
    ].map{ |location| File.expand_path(location) }.freeze

    class << self
      # Perform a smart search for knife.rb chef configuration file
      #
      # @return [Pathname]
      #   the path to the chef configuration
      def chef_config_path
        @chef_config_path ||= begin
          location = KNIFE_LOCATIONS.find{ |location| File.exists?(location) }

          if location.nil?
            raise ::Strainer::Error::ChefConfigNotFound, "Could not find a Chef configuration in any of the default locations. You can specify one with the `--config FILE` option"
          end

          Pathname.new(File.expand_path(location))
        end
      end

      # Set the chef_config_path
      #
      # @param [String] path
      #   the path to the config file
      # @return [Pathname]
      #   the supplied string as a Pathname
      def chef_config_path=(path)
        @chef_config = nil
        @chef_config_path = Pathname.new(File.expand_path(path))
        @chef_config_path
      end

      # Get the best chef configuration
      #
      # @return [Chef::Config]
      #   a chef configuration
      def chef_config
        @chef_config ||= begin
          unless File.exist?(chef_config_path)
            raise ::Strainer::Error::ChefConfigNotFound, "You specified a path to a Chef configuration file that did not exist: '#{chef_config_path}'"
          end

          Chef::Config.from_file(chef_config_path.to_s)
          Chef::Config
        end
      end
    end

    # Creates a Strainer runner
    #
    # @param [Array<String>] cookbook_names
    #   an array of cookbook_names to test and load into the sandbox
    # @param [Hash] options
    #   a list of options to pass along
    def initialize(cookbook_names, options = {})
      @options   = options
      @sandbox   = Strainer::Sandbox.new(cookbook_names, @options)
      @cookbooks = @sandbox.cookbooks
      @report    = {}

      @cookbooks.each do |cookbook|
        strainerfile = Strainer::Strainerfile.for(cookbook, options)
        Strainer.ui.header("# Straining '#{cookbook.cookbook_name} (v#{cookbook.version})'")

        strainerfile.commands.each do |command|
          success = command.run!

          @report[cookbook.cookbook_name] ||= {}
          @report[cookbook.cookbook_name][command.label] = success

          if @options[:fail_fast] && !success
            Strainer.ui.fatal "Exited early because '--fail-fast' was specified. Some tests may have been skipped!"
            abort
          end
        end
      end

      abort unless @report.values.collect(&:values).flatten.all?{|v| v == true}
    end
  end
end
