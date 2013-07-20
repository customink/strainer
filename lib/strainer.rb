#
# Copyright 2013, Seth Vargo <sethvargo@gmail.com>
# Copyright 2013, CustomInk, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'berkshelf'
require 'celluloid'
require 'pathname'
require 'thor'

module Strainer
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

require_relative 'berkshelf/extensions'
require_relative 'strainer/cli'
require_relative 'strainer/command'
require_relative 'strainer/errors'
require_relative 'strainer/runner'
require_relative 'strainer/sandbox'
require_relative 'strainer/strainerfile'
require_relative 'strainer/ui'
require_relative 'strainer/version'
