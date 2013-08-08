#
# Copyright 2013, Stafford Brunk <sbrunk@customink.com>
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

require_relative 'ui'

module Strainer
  class Shell < Thor::Shell::Color
    include UI

    class << self
      attr_accessor :enable_colors
    end

    # Should output have ANSI colors applied?
    def color_enabled?
      !self.class.enable_colors
    end

    # Set ANSI colors for the given string only if
    # colors are enabled for this shell
    #
    # @param [String]
    #   message to set colors on 
    # @param [Symbol] colors
    #   the colors to apply
    def set_color(string, *colors)
      color_enabled? ? string : super
    end
  end
end
