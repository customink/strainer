# Strainer

Strainer is a gem for isolating and testing individual chef cookbooks. It allows you to keep all your cookbooks in a single repository (saving you time and money), while having all the benefits of individual repositories.

Usage
-----
Strainer is a command line tool. The first thing you should do is add the following entry into your `.gitignore` and `chefignore` files:

    .colander

The `.colander` directory is where strainer puts all your temporary files for testing. You should not commit it to source control, nor should you upload it if sharing this cookbook with the community.

Next, create a `Colanderfile`. Cookbook-level Colanderfiles will take precedence over root-level ones. For simplicity, let's just create one in the root of our chef repository:

    # Colanderfile
    knife test: bundle exec knife cookbook test $COOKBOOK
    foodcritic: bundle exec foodcritic -f any $COOKBOOK

`Colanderfile` exposes two variables:

- `$COOKBOOK` - the current running cookbook
- `$SANDBOX` - the sandbox path

Just like foreman, the labels don't actually matter - they are only used in formatting the output.

That `Colanderfile` will run [foodcritic](https://github.com/acrmp/foodcritic) and knife test. I recommend this as the bare minimum for a cookbook test.

To strain, simply run the `strain` command and pass in the cookbooks to strain:

    # strains phantomjs and tmux
    $ bundle exec strain phantomjs tmux

This will first detect the cookbook dependencies, copy the cookbook and all dependencies into a sandbox. Then `knife test` and `foodcritic` will be run against both of the cookbooks. You can pass in as many cookbooks as you'd like.

Failing Quickly
---------------
As of `v0.0.4`, there's an option for `--fail-fast` that will fail immediately when any strain command returns a non-zero exit code:

    $ bundle exec strain phantomjs --fail-fast

This can save time, especially when running tests locally. This is *not* recommended on continuous integration.

Custom Foodcritic Rules
-----------------------
I always advocate using both [Etsy Foodcritic Rules](https://github.com/etsy/foodcritic-rules) and [CustomInk Foodcritic Rules](https://github.com/customink/foodcritic-rules) in all your projects. I also advocate keeping them all as submodules in `[Chef Repo]/foodcritic/...`. This makes strainer unhappy...

Strainer runs everything in an isolated sandbox, inside your Chef Repo. The root of your Chef Repo is two folders above the sandbox environment. This means, when including additional foodcritic rules, you need to do something like this:

    # Colanderfile
    foodcritic: bundle exec foodcritic -I ../../foodcritic/* -f any $COOKBOOK

Needs Your Help
---------------
This is a list of features or problem *you* can help solve! Fork and submit a pull request to make Strain even better!

- **Threading** - Run each cookbook's tests (or each cookbook tests test) in a separate thread
