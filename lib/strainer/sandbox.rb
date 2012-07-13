require 'fileutils'

module Strainer
  class Sandbox
    attr_reader :cookbooks

    def initialize(cookbooks = [], options = {})
      @cookbooks = [cookbooks].flatten
      @options = options

      clear_sandbox
      create_sandbox
    end

    def cookbook_path(cookbook)
      path = File.join(cookbooks_path, cookbook)
      raise "cookbook '#{cookbook}' was not found in #{cookbooks_path}" unless File.exists?(path)
      return path
    end

    def sandbox_path(cookbook = nil)
      File.expand_path( File.join(%W(colander cookbooks #{cookbook})) )
    end

    private
    def cookbooks_path
      @cookbooks_path ||= (@options[:cookbooks_path] || File.expand_path('cookbooks'))
    end

    def clear_sandbox
      FileUtils.rm_rf(sandbox_path)
    end

    def create_sandbox
      FileUtils.mkdir_p(sandbox_path)

      copy_globals
      copy_cookbooks
      place_knife_rb
    end

    def copy_globals
      files = %w(.rspec spec test)
      FileUtils.cp_r( Dir["{#{files.join(',')}}"], sandbox_path('..') )
    end

    def copy_cookbooks
      @cookbooks.each do |cookbook|
        FileUtils.cp_r(cookbook_path(cookbook), sandbox_path)
      end
    end

    def place_knife_rb
      chef_path = File.join(sandbox_path, '..','.chef')
      FileUtils.mkdir_p(chef_path)

      # build the contents
      contents = <<-EOH
cache_type 'BasicFile'
cache_options(:path => "\#{ENV['HOME']}/.chef/checksums")
cookbook_path '#{sandbox_path}'
EOH

      # create knife.rb
      File.open("#{chef_path}/knife.rb", 'w+'){ |f| f.write(contents) }
    end
  end
end
