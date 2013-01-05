module Strainer
  # Extend Thor::Shell::Color to provide nice helpers for outputting
  # to the console.
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  class UI < ::Thor::Shell::Color
    # Print the given message to STDOUT.
    #
    # @param [String]
    #   message the message to print
    # @param [Symbol] color
    #   the color to use
    # @param [Boolean] new_line
    #   include a new_line character
    def say(message = '', color = nil, new_line = nil)
      return if quiet?
      super(message, color)
    end
    alias_method :info, :say

    # Print the given message to STDOUT.
    #
    # @param [String] status
    #   the status to print
    # @param [String] message
    #   the message to print
    # @param [Boolean] log_status
    #   whether to log the status
    def say_status(status, message, log_status = true)
      return if quiet?
      super(status, message, log_status)
    end

    # Print a header message
    #
    # @param [String] message
    #   the message to print
    def header(message)
      return if quiet?
      say(message, [:black, :on_white])
    end

    # Print a green success message to STDOUT.
    #
    # @param [String] message
    #   the message to print
    # @param [Symbol] color
    #   the color to use
    def success(message, color = :green)
      return if quiet?
      say(message, color)
    end

    # Print a yellow warning message to STDOUT.
    #
    # @param [String] message
    #   the message to print
    # @param [Symbol] color
    #   the color to use
    def warn(message, color = :yellow)
      return if quiet?
      say(message, color)
    end

    # Print a red error message to the STDERR.
    #
    # @param [String] message
    #   the message to print
    # @param [Symbol] color
    #   the color to use
    def error(message, color = :red)
      return if quiet?
      message = set_color(message, *color) if color
      super(message)
    end
    alias_method :fatal, :error

    # Log a debugging message, if the proper environment
    # flag was specified.
    def debug(message)
      return if quiet?
      say('[DEBUG]   ' + message, :yellow) if ENV['STRAINER_DEBUG']
    end

    # Print a deprecation notice to STDERR.
    #
    # @param [String] message
    #   the message to print
    def deprecated(message)
      return if quiet?
      error('[DEPRECATION]   ' + message)
    end
  end
end
