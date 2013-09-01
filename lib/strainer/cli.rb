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

require 'buff/platform'
require 'strainer'
require_relative 'strainerfile'

module Strainer
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

      # Set the Strainer path if it's specified
      Strainer.sandbox_path = @options[:sandbox] if @options[:sandbox]

      # Use Strainer::Shell as the primary output shell
      Thor::Base.shell = Strainer::Shell

      # Set whether color output is enabled
      Thor::Base.shell.enable_colors = @options[:color]

      # Unfreeze the options Hash from Thor
      @options = options.dup

      # Use debugging output if asked
      $DEBUG = true if @options[:debug]
    end

    # global options
    map ['-v', '--version'] => :version
    class_option :cookbooks_path, :type => :string,  :aliases => '-p',  :desc => 'The path to the cookbook store', :banner => 'PATH'
    class_option :config,         :type => :string,  :aliases => '-c',  :desc => 'The path to the knife.rb/client.rb config'
    class_option :strainer_file,  :type => :string,  :aliases => '-s',  :desc => 'The path to the Strainer file to run against', :banner => 'FILE', :default => Strainer::Strainerfile::DEFAULT_FILENAME
    class_option :sandbox,        :type => :string,  :aliases => '-S',  :desc => 'The sandbox path (defaults to a temporary directory)', :default => Dir.mktmpdir
    class_option :debug,          :type => :boolean, :aliases => '-d',  :desc => 'Show debugging log output', :default => false
    class_option :color,          :type => :boolean, :aliases => '-C',  :desc => 'Enable color in Strainer output', :default => !Buff::Platform.windows?

    # strainer test *COOKBOOKS
    method_option :except,        :type => :array,   :aliases => '-e', :desc => 'Strainerfile labels to ignore'
    method_option :only,          :type => :array,   :aliases => '-o', :desc => 'Strainerfile labels to include'
    method_option :fail_fast,     :type => :boolean, :aliases => '-x', :desc => 'Stop termination immediately if a test fails', :banner => '', :default => false
    desc 'test [COOKBOOKS]', 'Run tests against the given cookbooks'
    def test(*cookbooks)
      Strainer.ui.debug "Called Strainer::Cli#test with #{cookbooks.inspect}"
      ret = Strainer::Runner.new(cookbooks, options).run!
      exit(ret)
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
      Strainer.ui.debug "Called Strainer::Cli#version"
      Strainer.ui.info Strainer::VERSION
    end
  end
end
