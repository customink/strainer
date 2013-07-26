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

require 'pty'

module Strainer
  # The Command class is responsible for a command (test) against a cookbook.
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  class Command
    # List of colors to choose from when outputting labels
    COLORS = %w(yellow blue magenta cyan).freeze

    # List of commands that must be run from inside a cookbook
    COOKBOOK_COMMANDS = %w(rspec kitchen)

    # @return [String]
    #   the "text" form of the command to run
    attr_reader :command

    # @return [String]
    #   the label for this command
    attr_reader :label

    # Parse a command out of the given string (line)
    #
    # @param [String] line
    #   the line to parse
    #   example: foodcritic -f any phantomjs
    def initialize(line, cookbook, options = {})
      Strainer.ui.debug "Created new command from '#{line}'"
      @label, @command = line.split(':', 2).map(&:strip)
      Strainer.ui.debug "  Label: #{@label.inspect}"
      Strainer.ui.debug "  Command: #{@command.inspect}"
      @cookbook = cookbook
    end

    # Run the given command against the cookbook
    #
    # @return [Boolean]
    #   `true` if the command exited successfully, `false` otherwise
    def run!
      title(label)

      inside do
        Strainer.ui.debug "Running '#{command}'"
        speak command
        PTY.spawn(command) do |r, _, pid|
          begin
            r.sync
            r.each_line { |line| speak line }
          rescue Errno::EIO => e
            # Ignore this. Otherwise errors will be thrown whenever
            # the process is closed
          ensure
            ::Process.wait pid
          end
        end

        unless $?.success?
          Strainer.ui.error label_with_padding + Strainer.ui.set_color('Terminated with a non-zero exit status. Strainer assumes this is a failure.', :red)
          Strainer.ui.error label_with_padding + Strainer.ui.set_color('FAILURE!', :red)
          false
        else
          Strainer.ui.success label_with_padding + Strainer.ui.set_color('SUCCESS!', :green)
          true
        end
      end
    end

    # Logic gate to determine if a command should be run from the sandbox or the cookbook.
    # @see {inside_cookbook}
    # @see {inside_sandbox}
    def inside(&block)
      if COOKBOOK_COMMANDS.any? { |c| command =~ /#{c}/ }
        Strainer.ui.debug "Detected '#{command}' should be run from inside the cookbook"
        inside_cookbook(&block)
      else
        Strainer.ui.debug "Detected '#{command}' should be run from inside the sandbox"
        inside_sandbox(&block)
      end
    end

    # Have this command output text, prefixing with its output with the
    # command name
    #
    # @param [String] message
    #   the message to speak
    # @param [Hash] options
    #   a list of options to pass along
    def speak(message, options = {})
      message.to_s.strip.split("\n").each do |line|
        next if line.strip.empty?

        line.gsub! Strainer.sandbox_path.to_s, @cookbook.original_path.dirname.to_s
        Strainer.ui.say label_with_padding + line, options
      end
    end

    private
    # Return the color associated with this label
    #
    # @return [Symbol]
    #   the color (as a symbol) associated with this label
    def color
      @color ||= COLORS[label.length%COLORS.length].to_sym
    end

    # Update the current process name and terminal title with
    # the given title.
    #
    # @param [String] title
    #   the title to update with
    def title(title)
      Strainer.ui.debug "Setting terminal title to '#{title}'"
      $0 = title
      printf "\033]0;#{title}\007"
    end

    # Get the label corresponding to this command with spacial padding
    #
    # @return [String]
    #   the padding and colored label
    def label_with_padding
      padded_label = label[0..20].ljust(20) + ' | '
      Strainer.ui.set_color padded_label, color
    end

    # Execute a block inside the sandbox directory defined in 'Strainer.sandbox_path'.
    # This will first change the 'PWD' env variable to the sandbox path, and then
    # pass the given block into 'Dir.chdir'. 'PWD' is restored to the original value
    # when the block is finished.
    #
    # @yield The block to execute inside the sandbox
    # @return [Boolean]
    #   `true` if the command exited successfully, `false` otherwise
    def inside_sandbox(&block)
      Strainer.ui.debug "Changing working directory to '#{Strainer.sandbox_path}'"
      original_pwd = ENV['PWD']

      ENV['PWD'] = Strainer.sandbox_path.to_s
      success = Dir.chdir(Strainer.sandbox_path, &block)
      ENV['PWD'] = original_pwd

      Strainer.ui.debug "Restored working directory to '#{original_pwd}'"
      success
    end

    # Execute a block inside the sandboxed cookbook directory.
    #
    # @yield The block to execute inside the cookbook sandbox
    # @return [Boolean]
    #   `true` if the command exited successfully, `false` otherwise
    def inside_cookbook(&block)
      cookbook_path = File.join(Strainer.sandbox_path.to_s, @cookbook.cookbook_name)
      Strainer.ui.debug "Changing working directory to '#{cookbook_path}'"
      original_pwd = ENV['PWD']

      ENV['PWD'] = cookbook_path
      success = Dir.chdir(cookbook_path, &block)
      ENV['PWD'] = original_pwd

      Strainer.ui.debug "Restoring working directory to '#{original_pwd}'"
      success
    end
  end
end
