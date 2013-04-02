module Strainer
  # The Runner class is responsible for executing the tests against cookbooks.
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  class Runner
    # Creates a Strainer runner
    #
    # @param [Array<String>] cookbook_names
    #   an array of cookbook_names to test and load into the sandbox
    # @param [Hash] options
    #   a list of options to pass along
    def initialize(cookbook_names, options = {})
      @options   = options
      @sandbox   = Strainer::Sandbox.new(cookbook_names, @options)
      @cookbooks = @sandbox.cookbooks
      @report    = {}

      @cookbooks.each do |cookbook|
        strainerfile = Strainer::Strainerfile.for(cookbook, options)
        Strainer.ui.header("# Straining '#{cookbook.cookbook_name} (v#{cookbook.version})'")

        strainerfile.commands.each do |command|
          success = command.run!

          @report[cookbook.cookbook_name] ||= {}
          @report[cookbook.cookbook_name][command.label] = success

          if @options[:fail_fast] && !success
            Strainer.ui.fatal "Exited early because '--fail-fast' was specified. Some tests may have been skipped!"
            abort
          end
        end
      end

      abort unless @report.values.collect(&:values).flatten.all? { |v| v == true }
    end
  end
end
