require 'berkshelf'
require 'berkshelf/extensions'
require 'pathname'
require 'thor'

require 'strainer/errors'

module Strainer
  autoload :Cli,            'strainer/cli'
  autoload :Command,        'strainer/command'
  autoload :Runner,         'strainer/runner'
  autoload :Sandbox,        'strainer/sandbox'
  autoload :Strainerfile,   'strainer/strainerfile'
  autoload :UI,             'strainer/ui'
  autoload :Version,        'strainer/version'

  class << self
    # The root of the application
    #
    # @return [Pathname]
    #   the path to the root of Strainer
    def root
      @root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end

    # The UI instance
    #
    # @return [Strainer::UI]
    #   an instance of the strainer UI
    def ui
      @ui ||= Strainer::UI.new
    end

    # Helper method to access a constant defined in Strainer::Sandbox that
    # specifies the location of the sandbox
    #
    # @return [Pathname]
    #   the path to the sandbox
    def sandbox_path
      Strainer::Sandbox::SANDBOX
    end

    # Helper method to access a constant defined in Strainer::Strainerfile that
    # specifies the filename for Strainer
    #
    # @return [String]
    #   the filename for Strainerfile
    def strainerfile_name
      Strainer::Strainerfile::FILENAME
    end
  end
end

# Sync STDOUT to get "real-time" output
STDOUT.sync = true
