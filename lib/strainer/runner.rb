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
      Strainer.ui.debug "Created new Strainer::Runner with #{cookbook_names.inspect}, options: #{options.inspect}"
      @sandbox   = Strainer::Sandbox.new(cookbook_names, options)
      @cookbooks = @sandbox.cookbooks
      @report    = {}

      @cookbooks.each do |cookbook|
        Strainer.ui.debug "Starting Runner for #{cookbook.cookbook_name} (#{cookbook.version})"
        strainerfile = Strainer::Strainerfile.for(cookbook, options)
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

      abort unless @report.values.collect(&:values).flatten.all? { |v| v == true }
    end
  end
end
