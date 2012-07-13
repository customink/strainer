module Strainer
  class Runner
    def initialize(sandbox, options = {})
      @sandbox = sandbox
      @cookbooks = @sandbox.cookbooks

      @results = Hash.new(0)

      @cookbooks.each do |cookbook|
        puts Color.negative{ "# Straining '#{cookbook}'" }
        commands_for(cookbook).collect do |command|
          run(command)
        end
        puts "\n\n\n"
      end

      abort unless @results[:failed].zero?
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

      puts [ label_with_padding(label), Color.bold{ Color.underscore{ command } } ].join(' ')
      output(label, `cd #{@sandbox.sandbox_path} && #{command}`)

      if $?.success?
        @results[:passed] += 1
        output(label, Color.green{'Success!'})
        return true
      else
        @results[:failed] += 1
        output(label, Color.red{'Failure!'})
        return false
      end
    end

    def output(label, data)
      data.to_s.strip.split("\n").each do |line|
        $stdout.puts [ label_with_padding(label), line ].join(' ')
        $stdout.flush
      end
    end
  end
end
