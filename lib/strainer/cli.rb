require 'optparse'

module Strainer
  class CLI
    def self.run(*args)
      parse_options(*args)

      @sandbox = Strainer::Sandbox.new(@cookbooks, @options)
      @runner = Strainer::Runner.new(@sandbox, @options)
    end

    private
    def self.parse_options(*args)
      @options = {}

      parser = OptionParser.new do |options|
        options.on nil, '--fail-fast', 'Fail fast' do |ff|
          @options[:fail_fast] = ff
        end

        options.on '-p PATH', '--cookbooks-path PATH', 'Path to the cookbooks' do |cp|
          @options[:cookbooks_path] = cp
        end

        options.on '-h', '--help', 'Display this help screen' do |h|
          puts options
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
