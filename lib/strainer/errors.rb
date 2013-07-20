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
    class StrainerfileNotFound < Base; status_code(110); end
  end
end
