module Strainer
  module Error
    # Base class for our custom errors to inherit from.
    #
    # @author Seth Vargo <sethvargo@gmail.com>
    class Base < StandardError
      # Helper method for creating errors using a given status code
      #
      # @param [Integer] code
      #   the status code for this error
      def self.status_code(code)
        define_method(:status_code) { code }
        define_singleton_method(:status_code) { code }
      end
    end

    # Raised when a required cookbook is not found.
    #
    # @author Seth Vargo <sethvargo@gmail.com>
    class CookbookNotFound < Base; status_code(100); end

    # Raised when Strainer is unable to find a Strainerfile.
    #
    # @author Seth Vargo <sethvargo@gmail.com>
    class StrainerfileNotFound < Base; status_code(101); end
  end
end
