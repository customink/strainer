require 'chef'
require 'chef/knife'
require 'fileutils'

module Strainer
  class Sandbox
    attr_reader :cookbooks

    def initialize(cookbooks = [], options = {})
      @options = options
      @cookbooks = load_cookbooks([cookbooks].flatten)

      clear_sandbox
      create_sandbox
    end

    def cookbook_path(cookbook)
      found_paths = cookbooks_path.select{ |path| File.exists?( File.join(path, cookbook.name.to_s) ) }

      if found_paths.empty?
        puts Color.red { "Cookbook '#{cookbook.name}' was not found in #{cookbooks_path}" }
        exit(1)
      elsif found_paths.size > 1
        puts Color.yellow { "Cookbook '#{cookbook.name}' was found in multiple paths: #{found_paths}." }
        puts Color.yellow { 'Strainer can only handle one cookbook per path at this time. Pull requests are welcome :)' }
        exit(1)
      end

      return File.join(found_paths[0], cookbook.name.to_s)
    end

    def sandbox_path(cookbook = nil)
      File.expand_path( File.join(%W(.colander cookbooks #{cookbook.is_a?(::Chef::CookbookVersion) ? cookbook.name : cookbook})) )
    end

    private
    # Load a specific cookbook by name
    def load_cookbook(cookbook_name)
      return cookbook_name if cookbook_name.is_a?(::Chef::CookbookVersion)
      loader = ::Chef::CookbookLoader.new(cookbooks_path)
      loader[cookbook_name]
    end

    # Load an array of cookbooks by name
    def load_cookbooks(cookbook_names)
      cookbook_names = [cookbook_names].flatten
      cookbook_names.collect{ |cookbook_name| load_cookbook(cookbook_name) }
    end

    def cookbooks_path
      @cookbooks_path ||= [@options[:cookbooks_path] || ( File.exists?(knife_rb_path) ? (Chef::Config.from_file(knife_rb_path) && Chef::Config.cookbook_path.compact ) : nil) || File.expand_path('cookbooks')].flatten.collect{ |p| File.expand_path(p) }
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
      files = %w(.rspec spec test foodcritic)
      FileUtils.cp_r( Dir["{#{files.join(',')}}"], sandbox_path('..') )
    end

    def copy_cookbooks
      (cookbooks + cookbooks_dependencies).each do |cookbook|
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

    def knife_rb_path
      File.join(Chef::Knife.chef_config_dir, 'knife.rb')
    end

    # Iterate over the cookbook's dependencies and ensure those cookbooks are
    # also included in our sandbox by adding them to the @cookbooks instance
    # variable. This method is actually semi-recursive because we append to the
    # end of the array on which we are iterating, ensuring we load all dependencies
    # dependencies.
    def cookbooks_dependencies
      @cookbooks_dependencies ||= begin
        $stdout.puts 'Loading cookbook dependencies...'

        loaded_dependencies = Hash.new(false)

        dependencies = @cookbooks.dup

        dependencies.each do |cookbook|
          cookbook.metadata.dependencies.keys.each do |dependency_name|
            unless loaded_dependencies[dependency_name]
              dependencies << load_cookbook(dependency_name)
              loaded_dependencies[dependency_name] = true
            end
          end
        end
      end
    end
  end
end
