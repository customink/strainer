module Strainer
  class Runner
    def initialize(sandbox, options = {})
      @sandbox = sandbox
      @cookbooks = @sandbox.cookbooks
      @options = options

      # need a variable at the root level to track whether the
      # build actually passed
      success = true

      @cookbooks.each do |cookbook|
        $stdout.puts
        $stdout.puts Color.negative{ "# Straining '#{cookbook.name}'" }

        commands_for(cookbook.name.to_s).collect do |command|
          success &= run(command)

          if fail_fast? && !success
            $stdout.puts [ label_with_padding(command[:label]), Color.red{ 'Exited early because --fail-fast was specified. Some tests may have been skipped!' } ].join(' ')
            abort
          end
        end

        $stdout.puts
      end

      # fail unless all commands returned successfully
      abort unless success
    end

    private
    def commands_for(cookbook_name)
      file = File.read( colanderfile_for(cookbook_name) )

      file = file.strip
      file = file.gsub('$COOKBOOK', cookbook_name)
      file = file.gsub('$SANDBOX', @sandbox.sandbox_path)

      lines = file.split("\n").reject{|c| c.strip.empty?}.compact

      # parse the line and split it into the label and command parts
      #
      # example line: foodcritic -f any phantomjs
      lines.collect do |line|
        split_line = line.split(':', 2)

        {
          :label => split_line[0].strip,
          :command => split_line[1].strip
        }
      end || []
    end

    def colanderfile_for(cookbook_name)
      cookbook_level = File.join(@sandbox.sandbox_path(cookbook_name), 'Colanderfile')
      root_level = File.expand_path('Colanderfile')

      if File.exists?(cookbook_level)
        cookbook_level
      elsif File.exists?(root_level)
        root_level
      else
        raise "Could not find Colanderfile in #{cookbook_level} or #{root_level}"
      end
    end

    def label_with_padding(label)
      max_length = 12
      colors = [ :blue, :cyan, :magenta, :yellow ]
      color = colors[label.length%colors.length]

      Color.send(color) do
        "#{label[0...max_length].ljust(max_length)} | "
      end
    end

    def run(command)
      Dir.chdir('.colander') do
        label = command[:label]
        command = command[:command]
        pretty_command = begin
          split = command.split(' ')
          path = split.pop
          short_path = path.split('.colander').last[1..-1]

          split.push short_path
          split.join(' ')
        end

        $stdout.puts [ label_with_padding(label), Color.bold{ Color.underscore{ pretty_command } } ].join(' ')

        result = format(label, `#{command}`)
        $stdout.puts result unless result.strip.empty?

        if $?.success?
          $stdout.puts format(label, Color.green{'Success!'})
          $stdout.flush
          return true
        else
          $stdout.puts format(label, Color.red{'Failure!'})
          $stdout.flush
          return false
        end
      end
    end

    def format(label, data)
      data.to_s.strip.split("\n").collect do |line|
        if %w(fatal error alert).any?{ |e| line =~ /^#{e}/i }
          [ label_with_padding(label), Color.red{ line } ].join(' ')
        elsif %w(warn).any?{ |e| line =~ /^#{e}/i }
          [ label_with_padding(label), Color.yellow{ line } ].join(' ')
        elsif %w(info debug).any?{ |e| line =~ /^#{e}/i }
          [ label_with_padding(label), Color.cyan{ line } ].join(' ')
        else
          [ label_with_padding(label), line ].join(' ')
        end
      end.join("\n")
    end

    def fail_fast?
      @options[:fail_fast]
    end
  end
end
