Strainer CHANGELOG
==================
v3.0.4
------
- Add Thor and Rake tasks

v3.0.3
------
- *(ignore this)*

v3.0.2
------
- Output summary message

v3.0.1
------
- Fix typo in CLI :default (#28)

v3.0.1
------
- Fix Berkshelf Chef Config

v3.0.0
------
- Upgrade Berkshelf dependency (#27)

v2.1.0
------
- Added `--sandbox` option (#24)
- Added automatic logging and logfile
- Added support for Windows output (since it can't handle colors)
- Moved sandbox out of gem directory
- Converted UI to a module instead of subclass of Thor

v2.0.1
------
- Lower threshold for detecting if the parent is a chef_repo

v2.0.0
------
- Magical improvements

v1.0.0
------
- Moved entirely to Berkshelf integration
- Moved entirely to thor
- **Breaking** - new command `strainer`, old command is deprecated and will be removed in `2.0.0`
- Sync output

v0.2.1
------
- Support a wider range of chef versions
- Package Windows JSON with gem
- Bug fixes

v0.1.0
------
- Enable loading of cookbook dependencies

v0.0.4
------
- Added `--fail-fast` option
