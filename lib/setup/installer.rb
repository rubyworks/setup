require 'setup/base'

module Setup

  # Installer class handles the actual install procedure.
  #
  # NOTE: This new version does not support per-directory hooks.
  #
  class Installer < Base

    #
    def install_prefix
      config.install_prefix
    end
    #attr_accessor :install_prefix

    # Install package.
    def install
      Dir.chdir(rootdir) do
        install_bin
        install_ext
        install_lib
        install_data
        install_man
        install_doc
        install_etc
        prune_install_record
      end
    end

    # Install binaries (executables).
    def install_bin
      return unless directory?('bin')
      io.puts "* bin -> #{config.bindir}" unless quiet?
      files = files('bin')
      install_files('bin', files, config.bindir, 0755)
      #install_shebang(files, config.bindir)
    end

    # Install shared extension libraries.
    def install_ext
      return unless directory?('ext')
      io.puts "* ext -> #{config.sodir}" unless quiet?
      files = files('ext')
      files = select_dllext(files)
      #install_files('ext', files, config.sodir, 0555)
      files.each do |file|
        name = File.join(File.dirname(File.dirname(file)), File.basename(file))
        dest = destination(config.sodir, name)
        install_file('ext', file, dest, 0555, install_prefix)
      end
    end

    # Install library files.
    def install_lib
      return unless directory?('lib')
      io.puts "* lib -> #{config.rbdir}" unless quiet?
      files = files('lib')
      install_files('lib', files, config.rbdir, 0644)
    end

    # Install shared data.
    def install_data
      return unless directory?('data')
      io.puts "* data -> #{config.datadir}" unless quiet?
      files = files('data')
      install_files('data', files, config.datadir, 0644)
    end

    # Install configuration.
    def install_etc
      return unless directory?('etc')
      io.puts "* etc -> #{config.sysconfdir}" unless quiet?
      files = files('etc')
      install_files('etc', files, config.sysconfdir, 0644)
    end

    # Install manpages.
    def install_man
      return unless directory?('man')
      io.puts "* man -> #{config.mandir}" unless quiet?
      files = files('man')
      install_files('man', files, config.mandir, 0644)
    end

    # Install documentation.
    #
    # TODO: The use of the project name in the doc directory
    # should be set during the config phase. Define a seperate
    # config method for it.
    def install_doc
      return unless config.doc?
      return unless directory?('doc')
      return unless project.name
      dir   = File.join(config.docdir, "ruby-{project.name}")
      io.puts "* doc -> #{dir}" unless quiet?
      files = files('doc')
      install_files('doc', files, dir, 0644)
    end

  private

    # Comfirm a +path+ is a directory and exists.
    def directory?(path)
      File.directory?(path)
    end

    # Get a list of project files given a project subdirectory.
    def files(dir)
      files = Dir["#{dir}/**/*"]
      files = files.select{ |f| File.file?(f) }
      files = files.map{ |f| f.sub("#{dir}/", '') }
      files
    end

    # Extract dynamic link libraries from all ext files.
    def select_dllext(files)
      ents = files.select do |file| 
        File.extname(file) == ".#{dllext}"
      end
      if ents.empty? && !files.empty?
        raise Error, "ruby extention not compiled: 'setup.rb setup' first"
      end
      ents
    end

    # Dynamic link library extension for this system.
    def dllext
      config.dlext
      #Configuration::RBCONFIG['DLEXT']
    end

    # Install project files.
    def install_files(dir, list, dest, mode)
      #mkdir_p(dest) #, install_prefix)
      list.each do |fname|
        rdest = destination(dest, fname)
        install_file(dir, fname, rdest, mode, install_prefix)
      end
    end

    # Install a project file.
    def install_file(dir, from, dest, mode, prefix=nil)
      mkdir_p(File.dirname(dest))
  
      if trace? or trial?
        #to = prefix ? File.join(prefix, dir, from) : File.join(dir, from)
        io.puts "install #{dir}/#{from} #{dest}"
      end

      return if trial?

      str = binread(File.join(dir, from))

      if diff?(str, dest)
        trace_off {
          rm_f(dest) if File.exist?(dest)
        }
        File.open(dest, 'wb'){ |f| f.write(str) }
        File.chmod(mode, dest)
      end

      record_installation(dest) # record file as installed
    end

    # Install a directory.
    #--
    # TODO: Surely this can be simplified.
    #++
    def mkdir_p(dirname) #, prefix=nil)
      #dirname = destination(dirname)
      #dirname = File.join(prefix, File.expand_path(dirname)) if prefix
      return if File.directory?(dirname)

      io.puts "mkdir -p #{dirname}" if trace? or trial?

      return if trial?

      # Does not check '/', it's too abnormal.
      dirs = File.expand_path(dirname).split(%r<(?=/)>)
      if /\A[a-z]:\z/i =~ dirs[0]
        disk = dirs.shift
        dirs[0] = disk + dirs[0]
      end
      dirs.each_index do |idx|
        path = dirs[0..idx].join('')
        unless File.dir?(path)
          Dir.mkdir(path)
        end
        record_installation(path)  # record directories made
      end
    end

    # Record that a file or directory was installed in the
    # install record file.
    def record_installation(path)
      File.open(install_record, 'a') do |f|
        f.puts(path)
      end
      #io.puts "installed #{path}" if trace?
    end

    # Remove duplicates from the install record.
    def prune_install_record
      entries = File.read(install_record).split("\n")
      entries.uniq!
      File.open(install_record, 'w') do |f|
        f << entries.join("\n")
        f << "\n"
      end
    end

    # Get the install record file name, and ensure it's location
    # is prepared (ie. make it's directory).
    def install_record
      @install_record ||= (
        file = INSTALL_RECORD
        dir  = File.dirname(file)
        unless File.directory?(dir)
          FileUtils.mkdir_p(dir)
        end
        file
      )
    end

    #realdest = prefix ? File.join(prefix, File.expand_path(dest)) : dest
    #realdest = File.join(realdest, from) #if File.dir?(realdest) #File.basename(from)) if File.dir?(realdest)

    # Determine actual destination including install_prefix.
    def destination(dir, file)
      dest = install_prefix ? File.join(install_prefix, File.expand_path(dir)) : dir
      dest = File.join(dest, file) #if File.dir?(dest)
      dest = File.expand_path(dest)
      dest
    end

    # Is a current project file different from a previously
    # installed file?
    def diff?(new_content, path)
      return true unless File.exist?(path)
      new_content != binread(path)
    end

    # Binary read.
    def binread(fname)
      File.open(fname, 'rb') do |f|
        return f.read
      end
    end

    # TODO: The shebang updating needs some work.
    #
    # I beleive that on unix-based systems <tt>#!/usr/bin/env ruby</tt>
    # is the appropriate shebang.

    #
    def install_shebang(files, dir)
      files.each do |file|
        path = File.join(dir, File.basename(file))
        update_shebang_line(path)
      end
    end

    #
    def update_shebang_line(path)
      return if trial?
      return if config.shebang == 'never'
      old = Shebang.load(path)
      if old
        if old.args.size > 1
          $stderr.puts "warning: #{path}"
          $stderr.puts "Shebang line has too many args."
          $stderr.puts "It is not portable and your program may not work."
        end
        new = new_shebang(old)
        return if new.to_s == old.to_s
      else
        return unless config.shebang == 'all'
        new = Shebang.new(config.rubypath)
      end
      $stderr.puts "updating shebang: #{File.basename(path)}" if trace?
      open_atomic_writer(path) do |output|
        File.open(path, 'rb') do |f|
          f.gets if old   # discard
          output.puts new.to_s
          output.print f.read
        end
      end
    end

    #
    def new_shebang(old)
      if /\Aruby/ =~ File.basename(old.cmd)
        Shebang.new(config.rubypath, old.args)
      elsif File.basename(old.cmd) == 'env' and old.args.first == 'ruby'
        Shebang.new(config.rubypath, old.args[1..-1])
      else
        return old unless config.shebang == 'all'
        Shebang.new(config.rubypath)
      end
    end

    #
    def open_atomic_writer(path, &block)
      tmpfile = File.basename(path) + '.tmp'
      begin
        File.open(tmpfile, 'wb', &block)
        File.rename tmpfile, File.basename(path)
      ensure
        File.unlink tmpfile if File.exist?(tmpfile)
      end
    end

    #
    class Shebang
      def Shebang.load(path)
        line = nil
        File.open(path) {|f|
          line = f.gets
        }
        return nil unless /\A#!/ =~ line
        parse(line)
      end

      def Shebang.parse(line)
        cmd, *args = *line.strip.sub(/\A\#!/, '').split(' ')
        new(cmd, args)
      end

      def initialize(cmd, args = [])
        @cmd = cmd
        @args = args
      end

      attr_reader :cmd
      attr_reader :args

      def to_s
        "#! #{@cmd}" + (@args.empty? ? '' : " #{@args.join(' ')}")
      end
    end

  end

end

