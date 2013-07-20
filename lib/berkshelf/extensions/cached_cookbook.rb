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

module Berkshelf
  # Extensions on Berkshelf::CachedCookbook
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  class CachedCookbook
    # @return [Pathname]
    #   the original location of this cookbook
    attr_reader :original_path

    # Allow overriding the path, but store the old path in another
    # instance variable.
    #
    # @param [Pathname] location
    #   the new location for this cookbook
    def path=(location)
      @original_path = @path.dup
      @path = location
    end
  end
end
