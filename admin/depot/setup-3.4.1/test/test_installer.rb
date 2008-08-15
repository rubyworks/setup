require 'setup'
require 'fileutils'
require 'stringio'
require 'test/unit'

class DummyConfig
  def initialize(config)
    @config = config
  end

  def [](key)
    @config[key]
  end

  def no_harm?
    false
  end

  def verbose?
    false
  end
end

class TestInstaller < Test::Unit::TestCase

  include FileUtils

  def setup
    rm_rf %w(srcdir objdir)
    mkdir %w(srcdir objdir)
    Dir.chdir 'objdir'
    $stderr, $orig_stderr = StringIO.new, $stderr
  end

  def teardown
    $stderr = $orig_stderr
    Dir.chdir '..'
    rm_rf %w(srcdir objdir)
  end

  def setup_installer(config = {})
    @installer = Installer.new(DummyConfig.new(config), '../srcdir', '.')
  end

  def do_update_shebang_line(id, str)
    create id, str
    @installer.update_shebang_line "../srcdir/#{id}"
    read(id)
  end

  def create(filename, content)
    File.open("../srcdir/#{filename}", 'wb') {|f|
      f.write content
    }
  end

  def read(filename)
    path = File.exist?(filename) ? filename : "../srcdir/#{filename}"
    File.open(path, 'rb') {|f|
      return f.read
    }
  end

  def test_update_shebang_line__never
    setup_installer 'shebang' => 'never', 'rubypath' => 'ERROR'
    assert_equal "#!/usr/local/bin/ruby\nprogram",
        do_update_shebang_line('ruby', "#!/usr/local/bin/ruby\nprogram")
    assert_equal "#! /usr/local/bin/ruby\nprogram",
        do_update_shebang_line('ruby-sp', "#! /usr/local/bin/ruby\nprogram")
    assert_equal "#!/usr/local/bin/ruby -Ke\nprogram",
        do_update_shebang_line('ruby-arg', "#!/usr/local/bin/ruby -Ke\nprogram")
    assert_equal "#!/usr/bin/ruby -n -p\nprogram",
        do_update_shebang_line('ruby-args', "#!/usr/bin/ruby -n -p\nprogram")
    assert_equal "#!/usr/bin/env ruby\nprogram",
        do_update_shebang_line('env-ruby', "#!/usr/bin/env ruby\nprogram")
    assert_equal "#!/usr/bin/env perl\nprogram",
        do_update_shebang_line('env-noruby', "#!/usr/bin/env perl\nprogram")
    assert_equal "#!/bin/sh\nprogram",
        do_update_shebang_line('interp', "#!/bin/sh\nprogram")
    assert_equal "#!/bin/sh -l -r -\nprogram",
        do_update_shebang_line('interp-args', "#!/bin/sh -l -r -\nprogram")
    assert_equal "program",
        do_update_shebang_line('bare', "program")
    assert_equal "\001\002\003\n\004\005\006",
        do_update_shebang_line('binary', "\001\002\003\n\004\005\006")
  end

  def test_update_shebang_line__all
    setup_installer 'shebang' => 'all', 'rubypath' => 'RUBYPATH'
    assert_equal "#! RUBYPATH\nprogram",
        do_update_shebang_line('ruby', "#!/usr/local/bin/ruby\nprogram")
    assert_equal "#! RUBYPATH\nprogram",
        do_update_shebang_line('ruby-sp', "#! /usr/local/bin/ruby\nprogram")
    assert_equal "#! RUBYPATH -Ke\nprogram",
        do_update_shebang_line('ruby-arg', "#!/usr/local/bin/ruby -Ke\nprogram")
    assert_equal "#! RUBYPATH -n -p\nprogram",
        do_update_shebang_line('ruby-args', "#!/usr/bin/ruby -n -p\nprogram")
    assert_equal "#! RUBYPATH\nprogram",
        do_update_shebang_line('env-ruby', "#!/usr/bin/env ruby\nprogram")
    assert_equal "#! RUBYPATH\nprogram",
        do_update_shebang_line('env-noruby', "#!/usr/bin/env perl\nprogram")
    assert_equal "#! RUBYPATH\nprogram",
        do_update_shebang_line('interp', "#!/bin/sh\nprogram")
    assert_equal "#! RUBYPATH\nprogram",   # args removed
        do_update_shebang_line('interp-args', "#!/bin/sh -l -r -\nprogram")
    assert_equal "#! RUBYPATH\nprogram",
        do_update_shebang_line('bare', "program")
    assert_equal "#! RUBYPATH\n\001\002\003\n\004\005\006",
        do_update_shebang_line('binary', "\001\002\003\n\004\005\006")
  end

  def test_update_shebang_line__ruby
    setup_installer 'shebang' => 'ruby', 'rubypath' => 'RUBYPATH'
    assert_equal "#! RUBYPATH\nprogram",
        do_update_shebang_line('ruby', "#!/usr/local/bin/ruby\nprogram")
    assert_equal "#! RUBYPATH\nprogram",
        do_update_shebang_line('ruby-sp', "#! /usr/local/bin/ruby\nprogram")
    assert_equal "#! RUBYPATH -Ke\nprogram",
        do_update_shebang_line('ruby-arg', "#!/usr/local/bin/ruby -Ke\nprogram")
    assert_equal "#! RUBYPATH -n -p\nprogram",
        do_update_shebang_line('ruby-args', "#!/usr/bin/ruby -n -p\nprogram")
    assert_equal "#! RUBYPATH\nprogram",
        do_update_shebang_line('env-ruby', "#!/usr/bin/env ruby\nprogram")
    assert_equal "#!/usr/bin/env perl\nprogram",
        do_update_shebang_line('env-noruby', "#!/usr/bin/env perl\nprogram")
    assert_equal "#!/bin/sh\nprogram",
        do_update_shebang_line('interp', "#!/bin/sh\nprogram")
    assert_equal "#!/bin/sh -l -r -\nprogram",
        do_update_shebang_line('interp-args', "#!/bin/sh -l -r -\nprogram")
    assert_equal "program",
        do_update_shebang_line('bare', "program")
    assert_equal "\001\002\003\n\004\005\006",
        do_update_shebang_line('binary', "\001\002\003\n\004\005\006")
  end

end
