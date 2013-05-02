require 'equivalence'

module Strainer
  # The Runner class is responsible for executing the tests against cookbooks.
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  class Runner
    # Define equivalence information for Runner
    # See https://github.com/ernie/equivalence
    extend Equivalence
    equivalence :@cookbook_names, :@options

    attr_reader :cookbooks

    # Creates a Strainer runner
    #
    # @param [Array<String>] cookbook_names
    #   an array of cookbook_names to test and load into the sandbox
    # @param [Hash] options
    #   a list of options to pass along
    def initialize(cookbook_names, options = {})
      Strainer.ui.debug "Created new Strainer::Runner with #{cookbook_names.inspect}, options: #{options.inspect}"

      @cookbook_names = cookbook_names
      @options = options
      @sandbox   = Strainer::Sandbox.new(cookbook_names, options)
      @report    = {}
      @cookbooks = {}

      load_strainerfiles
    end

    # Runs the Strainer runner
    def run
      @cookbooks.each do |name, c|
        cookbook = c[:cookbook]
        strainerfile = c[:strainerfile]

        Strainer.ui.debug "Starting Runner for #{cookbook.cookbook_name} (#{cookbook.version})"
        Strainer.ui.header("# Straining '#{cookbook.cookbook_name} (v#{cookbook.version})'")

        strainerfile.commands.each do |command|
          success = command.run!

          @report[cookbook.cookbook_name] ||= {}
          @report[cookbook.cookbook_name][command.label] = success
          Strainer.ui.debug "Strainer::Runner#report: #{@report.inspect}"

          if options[:fail_fast] && !success
            Strainer.ui.debug "Run was not successful and --fail-fast was specified"
            Strainer.ui.fatal "Exited early because '--fail-fast' was specified. Some tests may have been skipped!"
            abort
          end
        end
      end

      abort unless @report.values.collect(&:values).flatten.all?
    end

    private
    def load_strainerfiles
      @sandbox.cookbooks.each do |cookbook|
        @cookbooks[cookbook.name] = {
          cookbook: cookbook,
          strainerfile: Strainer::Strainerfile.for(cookbook, @options)
        }
      end
    end
  end
end
