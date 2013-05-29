module Strainer
  # The Runner class is responsible for executing the tests against cookbooks.
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  class Runner
    attr_reader :cookbooks, :cookbook_names, :options

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
    def run!
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

      # Move the logfile back over
      FileUtils.mv(Strainer.logfile_path, Strainer.sandbox_path.join('strainer.out'))

      abort unless @report.values.collect(&:values).flatten.all?
    end

    def hash
      [@cookbook_names, @options].hash
    end

    def eql?(runner)
      self.class == runner.class &&
        self.cookbook_names == runner.cookbook_names &&
        self.options == runner.options
    end
    alias_method :==, :eql?

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
