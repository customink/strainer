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
