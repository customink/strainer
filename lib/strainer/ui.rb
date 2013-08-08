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

require 'thor'

module Strainer
  # Extend Thor::Shell::Color to provide nice helpers for outputting
  # to the console.
  #
  # This module will also force UI calls to log to the output file.
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  module UI
    # Print the given message to STDOUT.
    #
    # @param [String]
    #   message the message to print
    # @param [Symbol] color
    #   the color to use
    # @param [Boolean] new_line
    #   include a new_line character
    def say(message = '', color = nil, new_line = nil)
      Strainer.log.info(message.gsub(/\e\[\d+[;\d]*m/, ''))

      return if quiet?
      super(message, color)
    end

    # Print the given message to STDOUT.
    # @see {say}
    def info(message = '', color = nil, new_line = nil)
      Strainer.log.info(message.gsub(/\e\[\d+[;\d]*m/, ''))

      return if quiet?
      super(message, color)
    end

    # Print the given message to STDOUT.
    #
    # @param [String] status
    #   the status to print
    # @param [String] message
    #   the message to print
    # @param [Boolean] log_status
    #   whether to log the status
    def say_status(status, message, log_status = true)
      Strainer.log.info("status: #{status}, message: #{message}")

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
      Strainer.log.error(message)

      return if quiet?
      message = set_color(message, *color) if color
      super(message)
    end
    alias_method :fatal, :error

    # Log a debugging message, if the proper environment
    # flag was specified.
    def debug(message)
      return if quiet?
      say('[DEBUG]   ' + message, :yellow) if $DEBUG
    end

    # Print a deprecation notice to STDERR.
    #
    # @param [String] message
    #   the message to print
    def deprecated(message)
      return if quiet?
      warn('[DEPRECATION]   ' + message)
    end
  end
end
