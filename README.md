# AUPM

A Useless Package Manager for iOS.

## TODO

- [ ] Source Management
  - [x] List sources
  - [x] Ability to add/remove a source
  - [x] List packages from each source
   - [ ] Search through repo
- [x] Package Management
  - [x] List installed packages
  - [x] Ability to install packages from a repository
  - [x] Ability to remove packages installed on the device
  - [ ] Ability to reinstall packages that are installed from a repository
  - [ ] Ability to downgrade a package from a repository if the repository provides a previous version
  - [x] View a packages depiction if one is available
  - [x] Display package details on the depiction page
- [ ] Search
  - [ ] Search through database for packages
- [ ] Updates
  - [x] Display updated packages in order by date
  - [ ] Display packages that have updates
- [ ] Support for most modern iOS versions

## Installation

1. Install theos from [theos/theos](https://www.github.com/theos/theos)
2. Clone this repository
3. Run `make do`
