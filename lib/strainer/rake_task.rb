require 'rake'
require 'rake/tasklib'
require 'strainer/cli'

module Strainer
  # Run Strainer from rake
  #
  # @example
  #   desc "Run Strainer with Rake"
  #   Strainer::RakeTask.new(:strainer) do |strainer|
  #     strainer.except = ['kitchen']
  #   end
  class RakeTask < ::Rake::TaskLib
    # @return [Symbol]
    attr_accessor :name

    # @return [Hash]
    attr_reader :options

    def initialize(task_name = nil)
      @options = {}
      @name    = (task_name || :strainer).to_sym

      yield self if block_given?

      desc "Run Strainer" unless ::Rake.application.last_comment
      task name, :cookbook_name do |t, args|
        require 'strainer'
        Strainer::Runner.new(Array(args[:cookbook_name]), options)
      end
    end

    Strainer::Cli.class_options.each do |option|
      name = option.first

      define_method(name) do
        options[name.to_sym]
      end

      define_method("#{name}=") do |value|
        options[name.to_sym] = value
      end
    end

    Striner::Cli.commands['test'].options.each do |key|
      name = key.first

      define_method(name) do
        options[name.to_sym]
      end

      define_method("#{name}=") do |value|
        options[name.to_sym] = value
      end
    end

    # Set the path to the strainerfile
    #
    # @param [String] file
    def strainerfile=(file)
      options[:strainerfile] = file
    end
  end
end
