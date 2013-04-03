require 'pty'

module Strainer
  # The Command class is responsible for a command (test) against a cookbook.
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  class Command
    # List of colors to choose from when outputting labels
    COLORS = %w(yellow blue magenta cyan).freeze

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

      inside_sandbox do
        Strainer.ui.debug "Running '#{command}'"
        speak command
        PTY.spawn command do |r, _, pid|
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

    # Execute a block inside the sandbox directory defined in 'Strainer.sandbox_path'.
    # This will first change the 'PWD' env variable to the sandbox path, and then
    # pass the given block into 'Dir.chdir'. 'PWD' is restored to the original value
    # when the block is finished.
    #
    # @yield The block to execute inside the sandbox
    def inside_sandbox(&block)
      Strainer.ui.debug "Changing working directory to '#{Strainer.sandbox_path}'"
      original_pwd = ENV['PWD']

      ENV['PWD'] = Strainer.sandbox_path.to_s
      Dir.chdir(Strainer.sandbox_path, &block)
      ENV['PWD'] = original_pwd

      Strainer.ui.debug "Restored working directory to '#{original_pwd}'"
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
  end
end
