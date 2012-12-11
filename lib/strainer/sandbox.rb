module Strainer
  # Manages the Strainer sandbox (playground) for isolated testing.
  #
  # @author Seth Vargo <sethvargo@gmail.com>
  class Sandbox
    # The path to the testing sandbox inside the gem.
    SANDBOX = Strainer.root.join('sandbox').freeze

    # @return [Array<Berkshelf::CachedCookbook>]
    #   an array of cookbooks in this sandbox
    attr_reader :cookbooks

    # Create a new sandbox for the given cookbooks
    #
    # @param [Array<String>] cookbook_names
    #   the list of cookbooks to copy into the sandbox
    # @param [Hash] options
    #   a list of options to pass along
    def initialize(cookbook_names, options = {})
      @options   = options
      @cookbooks = load_cookbooks(cookbook_names)

      reset_sandbox
      copy_cookbooks
    end

    # Clear out the existing sandbox and create the directories
    def reset_sandbox
      destroy_sandbox
      create_sandbox
    end

    # Destroy the current sandbox, if it exists
    def destroy_sandbox
      FileUtils.rm_rf(SANDBOX) if File.directory?(SANDBOX)
    end

    # Create the sandbox unless it already exits
    def create_sandbox
      unless File.directory?(SANDBOX)
        FileUtils.mkdir_p(SANDBOX)
        copy_globals
        place_knife_rb
      end
    end

    # Copy over a whitelist of common files into our sandbox
    def copy_globals
      files = Dir[*%W(#{Strainer.strainerfile_name} foodcritic .rspec spec test)]
      FileUtils.cp_r(files, SANDBOX)
    end

    # Create a basic knife.rb file to ensure tests run successfully
    def place_knife_rb
      chef_path = SANDBOX.join('.chef')
      FileUtils.mkdir_p(chef_path)

      # Build the contents
      contents = <<-EOH
cache_type 'BasicFile'
cache_options(:path => "\#{ENV['HOME']}/.chef/checksums")
cookbook_path '#{SANDBOX}'
EOH

      # Create knife.rb
      File.open("#{chef_path}/knife.rb", 'w+'){ |f| f.write(contents) }
    end

    # Copy all the cookbooks provided in {#initialize} to the isolated sandbox location
    def copy_cookbooks
      cookbooks_and_dependencies.each do |cookbook|
        sandbox_path = SANDBOX.join(cookbook.cookbook_name)

        # Copy the files to our sandbox
        FileUtils.cp_r(cookbook.path, sandbox_path)

        # Override the @path location so we don't need to create a new object
        cookbook.path = sandbox_path
      end
    end

    # Load a cookbook from the given array of cookbook names
    #
    # @param [Array<String>] cookbook_names
    #   the list of cookbooks to search for
    # @return [Array<Berkshelf::CachedCookbook>]
    #   the array of cached cookbooks
    def load_cookbooks(cookbook_names)
      cookbook_names.collect{ |cookbook_name| load_cookbook(cookbook_name) }
    end

    # Load an individual cookbook by its name
    #
    # @param [String] cookbook_name
    #   the name of the cookbook to load
    # @return [Berkshelf::CachedCookbook]
    #   the cached cookbook
    # @raise [Strainer::Error::CookbookNotFound]
    #   when the cookbook was not found in any of the sources
    def load_cookbook(cookbook_name)
      cookbook = cookbooks_paths.collect do |path|
        begin
          Berkshelf::CachedCookbook.from_path(path.join(cookbook_name))
        rescue Berkshelf::CookbookNotFound
          # move onto the next source...
          nil
        end
      end.compact.last

      cookbook ||= Berkshelf.cookbook_store.cookbooks(cookbook_name).last

      unless cookbook
        raise Strainer::Error::CookbookNotFound, "Could not find cookbook #{cookbook_name} in any of the sources."
      end

      cookbook
    end

    # Dynamically builds a list of possible cookbook paths from the
    # `@options` hash, Berkshelf config, and Chef config, and a logical
    # guess
    #
    # @return [Array<Pathname>]
    #   a list of possible cookbook locations
    def cookbooks_paths
      @cookbooks_paths ||= begin
        paths = [
          @options[:cookbooks_path],
          Strainer::Runner.chef_config.cookbook_path,
          Berkshelf::Config.chef_config.cookbook_path,
          'cookbooks'
        ].flatten.compact.map{ |path| Pathname.new(File.expand_path(path)) }.uniq

        paths.select{ |path| File.exists?(path) }
      end
    end

    # Collect all cookbooks and the dependencies specified in their metadata.rb
    # for copying
    #
    # @return [Array<Berkshelf::CachedCookbook>]
    #   a list of cached cookbooks
    def cookbooks_and_dependencies
      loaded_dependencies = Hash.new(false)

      dependencies = @cookbooks.dup
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
