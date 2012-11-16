require 'berkshelf'
require 'chef'
require 'chef/knife'
require 'fileutils'

module Strainer
  class Sandbox
    class << self
      def path
        @@path ||= File.expand_path( File.join('.colander') )
      end

      def cookbook_path(*extra)
        File.expand_path( File.join( Sandbox.path, 'cookbooks', extra ) )
      end
    end

    attr_reader :cookbooks, :options

    def initialize(cookbook_names = [], options = {})
      @options = options
      @cookbooks = load_cookbooks(cookbook_names)

      clear_sandbox
      create_sandbox
    end

    def load_cookbooks(cookbook_names = [])
      cookbooks = cookbook_names.collect{ |cookbook_name| load_cookbook(cookbook_name) }
    end

    def load_cookbook(cookbook_name)
      cookbook = berkshelf_cookbook(cookbook_name) || cookbooks_path.collect do |path|
        begin
          Berkshelf::CachedCookbook.from_path(File.join(path, cookbook_name))
        rescue Berkshelf::CookbookNotFound
          # move onto the next source...
          nil
        end
      end.compact.last

      raise Berkshelf::CookbookNotFound, "Could not find #{cookbook_name} in any of the sources" if cookbook.nil?
      cookbook
    end

    private
    def cookbooks_path
      @cookbooks_path ||= [
        options[:cookbooks_path],
        Berkshelf::Config.chef_config.cookbook_path,
        'cookbooks'
      ].flatten.compact.select do |path|
        File.exists?(File.expand_path(path))
      end.collect do |path|
        File.expand_path(path)
      end
    end

    def clear_sandbox
      FileUtils.rm_rf(Sandbox.path)
    end

    def create_sandbox
      FileUtils.mkdir_p(Sandbox.cookbook_path)

      copy_globals
      copy_cookbooks
      place_knife_rb
    end

    def copy_globals
      files = %w(.rspec spec test foodcritic)
      FileUtils.cp_r( Dir["{#{files.join(',')}}"], Sandbox.path )
    end

    def copy_cookbooks
      cookbooks_and_dependencies.each do |cookbook|
        FileUtils.cp_r(cookbook.path, File.join(Sandbox.cookbook_path, cookbook.cookbook_name))
      end
    end

    def place_knife_rb
      chef_path = File.join(Sandbox.path, '.chef')
      FileUtils.mkdir_p(chef_path)

      # build the contents
      contents = <<-EOH
cache_type 'BasicFile'
cache_options(:path => "\#{ENV['HOME']}/.chef/checksums")
cookbook_path '#{Sandbox.cookbook_path}'
EOH

      # create knife.rb
      File.open("#{chef_path}/knife.rb", 'w+'){ |f| f.write(contents) }
    end

    def knife_rb_path
      Berkshelf::Config.chef_config_path
    end

    def berkshelf_cookbook(cookbook)
      Berkshelf.cookbook_store.cookbooks(cookbook).last
    end

    # Iterate over the cookbook's dependencies and ensure those cookbooks are
    # also included in our sandbox by adding them to the @cookbooks instance
    # variable. This method is actually semi-recursive because we append to the
    # end of the array on which we are iterating, ensuring we load all dependencies
    # dependencies.
    def cookbooks_and_dependencies
      $stdout.puts 'Loading cookbook dependencies...'

      loaded_dependencies = Hash.new(false)

      dependencies = cookbooks.dup
      dependencies.each do |cookbook|
        loaded_dependencies[cookbook.cookbook_name] = true

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
