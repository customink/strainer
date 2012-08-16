module Strainer
  class Runner
    def initialize(sandbox, options = {})
      @sandbox = sandbox
      @cookbooks = @sandbox.cookbooks
      @options = options

      @cookbooks.each do |cookbook|
        $stdout.puts
        $stdout.puts Color.negative{ "# Straining '#{cookbook}'" }.to_s

        commands_for(cookbook).collect do |command|
          success = run(command)

          if fail_fast? && !success
            $stdout.puts [ label_with_padding(command[:label]), Color.red{ 'Exited early because --fail-fast was specified. Some tests may have been skipped!' } ].join(' ')
            abort
          end
        end

        $stdout.puts
      end
    end

    private
    def commands_for(cookbook)
      file = File.read( colanderfile_for(cookbook) )

      file = file.strip
      file = file.gsub('$COOKBOOK', cookbook)
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

    def colanderfile_for(cookbook)
      cookbook_level = File.join(@sandbox.sandbox_path(cookbook), 'Colanderfile')
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
      label = command[:label]
      command = command[:command]

      $stdout.puts [ label_with_padding(label), Color.bold{ Color.underscore{ command } } ].join(' ')

      result = format(label, `(cd #{@sandbox.sandbox_path} && #{command})`)
      $stdout.puts result unless result.strip.empty?

      if $?.success?
        $stdout.puts format(label, Color.green{'Success!'})
        $stdout.flush
        true
      else
        $stdout.puts format(label, Color.red{'Failure!'})
        $stdout.flush
        false
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
