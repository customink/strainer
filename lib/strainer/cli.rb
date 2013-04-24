require 'strainer'

module Strainer
  # Use our own custom shell
  Thor::Base.shell = Strainer::UI

  # Cli runner for Strainer
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  class Cli < Thor
    def self.dispatch(meth, given_args, given_opts, config)
      unless (given_args & ['-h', '--help']).empty?
        # strainer -h
        return super if given_args.length == 1

        # strainer test -h
        command = given_args.first
        super(meth, ['help', command].compact, nil, config)
      else
        super
      end
    end

    def initialize(*args)
      super(*args)

      # Override the config file if it's specified
      Berkshelf::Chef::Config.path = @options[:config] if @options[:config]

      # Use a different Strainerfile if one was given
      Strainer.strainerfile = File.expand_path(@options[:strainer_file])

      # Unfreeze the options Hash from Thor
      @options = options.dup

      # Use debugging output if asked
      $DEBUG = true if @options[:debug]
    end

    # global options
    map ['-v', '--version'] => :version
    class_option :cookbooks_path, :type => :string,  :aliases => '-p', :desc => 'The path to the cookbook store', :banner => 'PATH'
    class_option :config,         :type => :string,  :aliases => '-c', :desc => 'The path to the knife.rb/client.rb config'
    class_option :strainer_file,  :type => :string,  :aliases => '-s', :desc => 'The path to the Strainer file to run against', :banner => 'FILE', :default => Strainer::Strainerfile::DEFAULT_FILENAME
    class_option :debug,          :type => :boolean, :aliases => '-d', :desc => 'Show debugging log output', :default => false

    # strainer test *COOKBOOKS
    method_option :except,        :type => :array,   :aliases => '-e', :desc => 'Strainerfile labels to ignore'
    method_option :only,          :type => :array,   :aliases => '-o', :desc => 'Strainerfile labels to include'
    method_option :fail_fast,     :type => :boolean, :aliases => '-x', :desc => 'Stop termination immediately if a test fails', :banner => '', :default => false
    desc 'test [COOKBOOKS]', 'Run tests against the given cookbooks'
    def test(*cookbooks)
      Strainer.ui.debug "Called Strainer::Cli#test with #{cookbooks.inspect}"
      Strainer::Runner.new(cookbooks, options)
    end

    # strainer info
    desc 'info', 'Display version and copyright information'
    def info
      Strainer.ui.debug "Called Strainer::Cli#info"
      Strainer.ui.info "Strainer (#{Strainer::VERSION})"
      Strainer.ui.info "\n"
      Strainer.ui.debug "Opening file #{Strainer.root.join('LICENSE')}"
      Strainer.ui.info File.read Strainer.root.join('LICENSE')
    end

    # strainer -v
    desc 'version', 'Display the version information', hide: true
    def version
      Strainer.ui.debug "Called Strainer::Cli#veresion"
      Strainer.ui.info Strainer::VERSION
    end
  end
end
