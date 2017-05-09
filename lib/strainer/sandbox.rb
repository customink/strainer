#
# Copyright 2013, Seth Vargo <sethvargo@gmail.com>
# Copyright 2013, CustomInk, LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

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
      @options = options

      if chef_repo?
        Strainer.ui.debug "Detected as a chef repo"
        if cookbook_names.empty?
          Strainer.ui.fatal "You must specify one or more cookbook names to `strainer test`!"
          exit(false)
        else
          @cookbooks = load_cookbooks(cookbook_names)
        end
      elsif cookbook_repo?
        Strainer.ui.debug "Detected as a cookbook repo"
        unless cookbook_names.empty?
          Strainer.ui.warn "Supply specific cookbooks to a cookbook_repo is not supported. Use `strainer test` with no arguments instead."
        end
        @cookbooks = [load_self]
      else
        Strainer.ui.warn "I could not detect if you were a chef-repo or a cookbook!"
        @cookbooks = []
      end

      reset_sandbox
    end

    private
      # Clear out the existing sandbox and create the directories
      def reset_sandbox
        Strainer.ui.debug "Resetting sandbox..."
        destroy_sandbox
        create_sandbox
      end

      # Destroy the current sandbox, if it exists
      def destroy_sandbox
        if File.directory?(Strainer.sandbox_path)
          Strainer.ui.debug "  Destroying sandbox at '#{Strainer.sandbox_path}'"
          FileUtils.rm_rf(Strainer.sandbox_path)
        else
          Strainer.ui.debug "  Sandbox does not exist... skipping"
        end
      end

      # Create the sandbox unless it already exits
      def create_sandbox
        unless File.directory?(Strainer.sandbox_path)
          Strainer.ui.debug "  Creating sandbox at '#{Strainer.sandbox_path}'"
          FileUtils.mkdir_p(Strainer.sandbox_path)
        end

        copy_globals
        place_knife_rb
        copy_cookbooks
      end

      # Copy over a whitelist of common files into our sandbox
      def copy_globals
        if chef_repo?
          files = Dir[*%W(#{@options['strainer_file']} foodcritic .cane .rubocop.yml .kitchen.yml Berksfile README.md .rspec spec test)]
        elsif cookbook_repo?
          files = Dir[*%W(#{@options['strainer_file']} foodcritic .cane .rubocop.yml .kitchen.yml Berksfile README.md .rspec)]
        else
          files = []
        end

        Strainer.ui.debug "Copying '#{files}' to '#{Strainer.sandbox_path}'"
        FileUtils.cp_r(files, Strainer.sandbox_path)
      end

      # Create a basic knife.rb file to ensure tests run successfully
      def place_knife_rb
        chef_path = Strainer.sandbox_path.join('.chef')

        Strainer.ui.debug "Creating directory '#{chef_path}'"
        FileUtils.mkdir_p(chef_path)

        # Build the contents
        contents = <<-EOH
  cache_type 'BasicFile'
  cache_options(:path => "\#{ENV['HOME']}/.chef/checksums")
  cookbook_path '#{Strainer.sandbox_path}'
  EOH

        # Create knife.rb
        Strainer.ui.debug "Writing '#{chef_path}/knife.rb' with content: \n\n#{contents}\n"
        File.open("#{chef_path}/knife.rb", 'w+'){ |f| f.write(contents) }
      end

      # Copy all the cookbooks provided in {#initialize} to the isolated sandbox location
      def copy_cookbooks
        Strainer.ui.debug "Sandbox#copy_cookbooks"
        cookbooks_and_dependencies.each do |cookbook|
          cookbook_sandbox = Strainer.sandbox_path.join(cookbook.cookbook_name)

          # Copy the files to our sandbox
          Strainer.ui.debug "Copying '#{cookbook.name}' to '#{cookbook_sandbox}'"
          FileUtils.cp_r(cookbook.path, cookbook_sandbox)

          # Override the @path location so we don't need to create a new object
          cookbook.path = cookbook_sandbox
        end
      end

      # Load a cookbook from the given array of cookbook names
      #
      # @param [Array<String>] cookbook_names
      #   the list of cookbooks to search for
      # @return [Array<Berkshelf::CachedCookbook>]
      #   the array of cached cookbooks
      def load_cookbooks(cookbook_names)
        Strainer.ui.debug "Sandbox#load_cookbooks(#{cookbook_names.inspect})"
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
        Strainer.ui.debug "Sandbox#load_cookbook('#{cookbook_name.inspect}')"
        cookbook_path = cookbooks_paths.find { |path| path.join(cookbook_name).exist? }

        cookbook = if cookbook_path
          path = cookbook_path.join(cookbook_name)
          Strainer.ui.debug "  found cookbook at '#{path}'"

          begin
            Berkshelf::CachedCookbook.from_path(path)
          rescue Berkshelf::CookbookNotFound
            raise Strainer::Error::CookbookNotFound, "'#{path}' existed, but I could not extract a cookbook. Is there a 'metadata.rb'?"
          end
        else
          Strainer.ui.debug "  did not find '#{cookbook_name}' in any of the sources - resorting to the default cookbook_store..."
          Berkshelf.cookbook_store.cookbooks(cookbook_name).last
        end

        cookbook || raise(Strainer::Error::CookbookNotFound, "Could not find '#{cookbook_name}' in any of the sources.")
      end

      # Load the current root entirely as a cookbook. This is useful when testing within
      # a cookbook, instead of a chef repo
      def load_self
        Strainer.ui.debug "Sandbox#load_self"

        begin
          Berkshelf::CachedCookbook.from_path(File.expand_path('.'))
        rescue Berkshelf::CookbookNotFound
          raise Strainer::Error::CookbookNotFound, "'#{File.expand_path('.')}' existed, but I could not extract a cookbook. Is there a 'metadata.rb'?"
        end
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
            Berkshelf.chef_config[:cookbook_path],
            'cookbooks'
          ].flatten.compact.map{ |path| Pathname.new(File.expand_path(path)) }.uniq

          paths.select!{ |path| File.exists?(path) }
          Strainer.ui.debug "Setting Sandbox#cookbooks_paths to #{paths.map(&:to_s)}"
          paths
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

      # Determines if the current project is a cookbook repo
      #
      # @return [Boolean]
      #   true if the current project is a cookbook repo, false otherwise
      def cookbook_repo?
        @_cookbook_repo ||= File.exists?('metadata.rb')
      end

      # Determines if the current project is a chef repo
      #
      # @return [Boolean]
      #   true if the current project is a chef repo, false otherwise
      def chef_repo?
        @_chef_repo ||= begin
          chef_folders = %w(.chef certificates config cookbooks data_bags environments roles)
          (root_folders & chef_folders).size > 2
        end
      end

      # Return a list of all directory folders at the root of the repo.
      # This is useful for detecting if it's a chef repo or cookbook
      # repo.
      #
      # @return [Array]
      #   the list of root-level directories
      def root_folders
        @root_folders ||= Dir.glob("#{Dir.pwd}/*", File::FNM_DOTMATCH).collect do |f|
          File.basename(f) if File.directory?(f)
        end.reject { |dir| %w(. ..).include?(dir) }.compact!
      end

      # Determine if the current project is a git repo?
      #
      # @return [Boolean]
      #   true if a .git directory is found, false otherwise
      def git_repo?
        @_git_repo ||= root_folders.include?('.git')
      end

  end
end
