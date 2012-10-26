require 'optparse'

module Strainer
  class CLI
    def self.run(*args)
      parse_options(*args)

      if @cookbooks.empty?
        puts Color.red { 'ERROR: You did not specify any cookbooks!' }
      else
        @sandbox = Strainer::Sandbox.new(@cookbooks, @options)
        @runner = Strainer::Runner.new(@sandbox, @options)
      end
    end

    private
    def self.parse_options(*args)
      @options = {}

      parser = OptionParser.new do |options|
        # remove OptionParsers Officious['version'] to avoid conflicts
        options.base.long.delete('version')

        options.on nil, '--fail-fast', 'Fail fast' do |ff|
          @options[:fail_fast] = ff
        end

        options.on '-p PATH', '--cookbooks-path PATH', 'Path to the cookbooks' do |cp|
          @options[:cookbooks_path] = cp
        end

        options.on '-h', '--help', 'Display this help screen' do
          puts options
          exit 0
        end

        options.on '-v', '--version', 'Display the current version' do
          require 'strainer/version'
          puts Strainer::VERSION
          exit 0
        end
      end

      # Get the cookbook names. The options that aren't read by optparser are assummed
      # to be cookbooks in this case.
      @cookbooks = []
      parser.order!(args) do |noopt|
        @cookbooks << noopt
      end
    end
  end
end
