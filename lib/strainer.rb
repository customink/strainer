require 'berkshelf'
require 'berkshelf/extensions'
require 'celluloid'
require 'pathname'
require 'thor'

require 'strainer/errors'
require 'strainer/ui'

module Strainer
  autoload :Cli,            'strainer/cli'
  autoload :Command,        'strainer/command'
  autoload :Runner,         'strainer/runner'
  autoload :Sandbox,        'strainer/sandbox'
  autoload :Strainerfile,   'strainer/strainerfile'
  autoload :Version,        'strainer/version'

  class << self
    # The root of the application.
    #
    # @return [Pathname]
    #   the path to the root of Strainer
    def root
      @root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end

    # The UI instance.
    #
    # @return [Strainer::UI]
    #   an instance of the strainer UI
    def ui
      @ui ||= Thor::Base.shell.new
    end

    # Get the file logger for Strainer.
    #
    # The logger writes to a temporary file and then copies itself back
    # into the sandbox directory after the run. This is because Strainer
    # clears the sandbox and would delete the logfile after some
    # important debugging information was printed.
    #
    # @return [Logger]
    #   the file logger
    def log
      @logger ||= begin
        log = Logger.new(logfile_path)
        log.level = Logger::DEBUG
        log
      end
    end

    # The path to the Strainer sandbox. Defaults to a temporary
    # directory on the local file system.
    #
    # @return [Pathname]
    #   the path to the sandbox
    def sandbox_path
      @sandbox_path ||= Pathname.new(Dir.mktmpdir)
    end

    # Set Strainer's sandbox path, ensuring the given path exists.
    #
    # @param [#to_s] path
    #   the path to set
    #
    # @return [Pathname]
    #   the path to the Strainer sandbox
    def sandbox_path=(path)
      path = File.expand_path(path.to_s)

      # Make the directory unless it already exists
      FileUtils.mkdir_p(path) unless File.exists?(path)

      @sandbox_path = Pathname.new(path.to_s)
    end

    # The path to the temporary logfile for the strain.
    #
    # @return [Pathname]
    #   the path to the log file
    def logfile_path
      @logfile_path ||= Pathname.new(File.join(Dir.mktmpdir, 'strainer.out'))
    end
  end
end

# Sync STDOUT to get "real-time" output
STDOUT.sync = true
