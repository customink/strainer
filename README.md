# Strainer

Strainer is a gem for isolating and testing individual chef cookbooks. It allows you to keep all your cookbooks in a single repository (saving you time and money), while having all the benefits of individual repositories.

**IMPORTANT! Strainer is no longer maintained as monolithic Chef repositories are no longer recommended.** This documentation and repository are kept here for historical reasons.

Usage
-----
First, create a `Strainerfile`. Cookbook-level Strainerfiles will take precedence over root-level ones. For simplicity, let's just create one in the root of our chef repository:

    # Strainerfile
    knife test: bundle exec knife cookbook test $COOKBOOK
    foodcritic: bundle exec foodcritic -f any cookbooks/$COOKBOOK

`Strainerfile` exposes two variables:

- `$COOKBOOK` - the current running cookbook
- `$SANDBOX` - the sandbox path

Just like foreman, the labels don't actually matter - they are only used in formatting the output.

That `Strainerfile` will run [foodcritic](https://github.com/acrmp/foodcritic) and knife test. I recommend this as the bare minimum for a cookbook test.

`Strainerfile`s commands are run in the context to the sandbox directory. The sandbox is essentially a clone of your working directory. This can be a bit confusing. `knife cookbook test` requires that you run your command against the "root" directory, yet foodcrtitic and chefspec require you run inside an actual cookbook. Here's a quick example to clear up some confusion:

    # Strainerfile
    knife test: bundle exec knife cookbook test $COOKBOOK
    foodcritic: bundle exec foodcritic -f any $SANDBOX/$COOKBOOK
    chefspec:   bundle exec rspec --color
    kitchen:    bundle exec kitchen test

To strain, simply run the `strainer` command and pass in the cookbook(s) to strain:

    $ bundle exec strainer test phantomjs tmux

This will first detect the cookbook dependencies, copy the cookbook and all dependencies into a sandbox. It will execute the contents of the `Strainerfile` on each cookbook.

Standalone
----------
As of `2.0.0`, Strainer supports "standalone" mode. This allows you to use Strainer file from within a cookbook. Instead of specifying the path for a cookbook, you just use `test`

    $ bundle exec strainer test

from the root of your cookbook. **Note**: your cookbook must have its own Gemfile and working directory.

Running on CI
-------------
It's very easy to use Strainer on your CI system. If your cookbook is run on Travis CI, for example, you could use the following `.travis.yml` file:

```yaml
rvm:
  - 1.9.3
  - 2.0.0
script: bundle exec strainer test --except kitchen
```

(Currently test-kitchen cannot be run on Travis, which is why it's skipped)

Berkshelf
---------
[Berkshelf](http://berkshelf.com/) is a tool for managing multiple cookbooks. It works very similar to how a `Gemfile` works with Rubygems. If you're already using Berkshelf, Strainer will work out of the box. If you're not using Berkshelf, Strainer will work out of the box.

Failing Quickly
---------------
As of `v0.0.4`, there's an option for `--fail-fast` that will fail immediately when any strain command returns a non-zero exit code:

    $ bundle exec strainer test phantomjs --fail-fast

This can save time, especially when running tests locally. This is *not* recommended on continuous integration.

Custom Sandboxes
----------------
By default, Strainer uses `Dir.mktmpdir` to execute your sandbox in. This means the directory is destroyed in due time. However, you can pass the `--sandbox` option to specify a specific sandbox.

Custom Foodcritic Rules
-----------------------
I always advocate using both [Etsy Foodcritic Rules](https://github.com/etsy/foodcritic-rules) and [CustomInk Foodcritic Rules](https://github.com/customink-webops/foodcritic-rules) in all your projects. I also advocate keeping them all as submodules in `[Chef Repo]/foodcritic/...`. This makes strainer unhappy...

Strainer runs everything in an isolated sandbox, inside your Chef Repo. When including additional foodcritic rules, you need to do something like this:

    # Strainerfile
    foodcritic: bundle exec foodcritic -I foodcritic/* -f any $SANDBOX/$COOKBOOK

Rake Task
---------
Strainer includes a Rake task for convenience:

```ruby
require 'strainer/rake_task'

Strainer::RakeTask.new(:strainer) do |s|
  s.except = [...]
  s.strainerfile = 'MyStrainerfile'
end
```

Thor Task
---------
Strainer includes a Thor task for convenience:

```ruby
require 'strainer/thor'

Strainer::Thor...
```

Needs Your Help
---------------
This is a list of features or problem *you* can help solve! Fork and submit a pull request to make Strain even better!

- **Threading** - Run each cookbook's tests (or each cookbook tests test) in a separate thread
