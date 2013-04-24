module Strainer
  # An instance of a Strainerfile.
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  class Strainerfile
    # The filename for the Strainerfile
    DEFAULT_FILENAME = 'Strainerfile'

    class << self
      # (see #initialize)
      def for(cookbook, options = {})
        new(cookbook, options)
      end
    end

    # Instantiate an instance of this class from a cookbook
    #
    # @param [Berkshelf::CachedCookbook] cookbook
    #   the cached cookbook to search for a Strainerfile
    # @param [Hash] options
    #   a list of options to pass along
    # @return [Strainerfile]
    #   an instance of this class
    def initialize(cookbook, options = {})
      @cookbook = cookbook
      @options = options

      locations = [
        @cookbook.path.join(options[:strainer_file]),
        Strainer.sandbox_path.join(options[:strainer_file])
      ]

      @strainerfile = locations.find{ |location| File.exists?(location) }

      raise Strainer::Error::StrainerfileNotFound, "Could not find a Strainerfile named '#{options[:strainer_file]}' for cookbook '#{cookbook.cookbook_name}'." unless @strainerfile

      load!
    end

    # Get the list of commands to run, filtered by the `@options` hash for either
    # `:ignore` or `:only`
    #
    # @return [Array<Strainer::Command>]
    #   the list of commands to execute
    def commands
      @commands ||= if @options[:except]
        @all_commands.reject{ |command| @options[:except].include?(command.label) }
      elsif @options[:only]
        @all_commands.select{ |command| @options[:only].include?(command.label) }
      else
        @all_commands
      end
    end

    private
    # Parse the given Strainerfile
    def load!
      return if @all_commands
      contents = File.read @strainerfile
      contents.strip!
      contents.gsub! '$COOKBOOK', @cookbook.cookbook_name
      contents.gsub! '$SANDBOX',  Strainer.sandbox_path.to_s

      # Drop empty lines and comments
      lines = contents.split("\n")
      lines.reject!{ |line| line.strip.empty? || line.strip.start_with?('#') }
      lines.compact!
      lines ||= []

      # Parse the line and split it into the label and command parts
      #
      # @example Example Line
      #   foodcritic -f any phantomjs
      @all_commands = lines.collect{ |line| Command.new(line, @cookbook, @options) }
    end
  end
end
