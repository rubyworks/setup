---
source:
- meta
- PROFILE
- profile.yml
authors:
- name: Minero Aoki
  email: aamine@loveruby.net
- name: Thomas Swyer
  email: transfire@gmail.com
copyrights:
- holder: Rubyworks
  year: '2009'
  license: BSD-2-Clause
- holder: Minero Aoki
  year: '2005'
  license: Ruby
requirements:
- name: ae
  groups:
  - test
  development: true
- name: cucumber
  groups:
  - test
  development: true
- name: detroit
  groups:
  - build
  development: true
dependencies: []
alternatives: []
conflicts: []
repositories:
- uri: git://github.com/rubyworks/setup.git
  scm: git
  name: upstream
resources:
  home: http://rubyworks.github.com/setup
  code: http://github.com/rubyworks/setup
  bugs: http://github.com/rubyworks/setup/issues
  old: http://setup.rubyforge.org
extra: {}
load_path:
- lib
revision: 0
created: '2008-08-01'
summary: Setup.rb as a stand-alone application.
version: 5.1.0
name: setup
title: Setup
description: Every Rubyist is aware of Minero Aoki's ever useful setup.rb script.
  It's how most of us used to install our ruby programs before RubyGems came along.And
  it's still mighty useful in certain scenarios, not the least of which is the job
  of the distribution package managers. Setup converts setup.rb into a stand-alone
  application. No longer will you need distribute setup.rb with you Ruby packages.
  Just instruct your users to use Setup.
organization: Rubyworks
date: '2012-03-18'
