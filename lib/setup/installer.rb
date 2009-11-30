require 'setup/base'

module Setup

  # Installer class handles the actual install procedure.
  #
  # THIS IS A WORK IN PROGRESS REWRITE.
  #
  # This version will not support per-directory hooks.
  #
  class Installer < Base

    #
    attr_accessor :install_prefix

    # Install package.
    def install
      Dir.chdir(rootdir) do
        install_bin
        install_lib
        install_data
        install_etc
        install_man
        install_doc
      end
    end

    # Install binaries (executables).
    def install_bin
      return unless directory?('bin')
      files = files('bin')
      install_files('bin', files, config.bindir, 0755)
      #install_shebang(files, config.bindir)
    end

    # Install shared extension libraries.
    def install_ext
      return unless directory?('ext')
      files = files('ext')
      files = select_dllext(files)
      install_files('etc', files, config.sodir, 0555)
    end

    # Install library files.
    def install_lib
      return unless directory?('lib')
      files = files('lib')
      install_files('lib', files, config.rbdir, 0644)
    end

    # Install shared data.
    def install_data
      return unless directory?('data')
      files = files('data')
      install_files('data', files, config.datadir, 0644)
    end

    # Install configuration.
    def install_etc
      return unless directory?('etc')
      files = files('etc')
      install_files('etc', files, config.sysconfdir, 0644)
    end

    # Install manpages.
    def install_man
      return unless directory?('man')
      files = files('man')
      install_files('man', files, config.mandir, 0644)
    end

    # Install documentation.
    def install_doc
      return unless directory?('doc')
      files = files('doc')
      install_files('doc', files, config.docdir, 0644)
    end

  private

    def directory?(dir)
      File.directory?(dir)
    end

    #
    def files(dir)
      files = Dir["#{dir}/**/*"]
      files = files.select{ |f| File.file?(f) }
      files = files.map{ |f| f.sub("#{dir}/", '') }
      files
    end

    #
    def select_dllext(files)
      ents = files.select do |file| 
        File.fnmatch?(File.basename(file), "*.#{dllext}")
      end
      if ents.empty? && !files.empty?
        raise Error, "no ruby extention exists: '#{$0} setup' first"
      end
      ents
    end

    #
    def dllext
      ConfigTable::RBCONFIG['DLEXT']
    end

    #
    def install_files(dir, list, dest, mode)
      #mkdir_p(dest) #, install_prefix)
      list.each do |fname|
        install_file(dir, fname, dest, mode, install_prefix)
      end
    end

    # TODO: Can this be simplified?
    def install_file(dir, from, dest, mode, prefix=nil)
      realdest = destination(dest, from)
      #realdest = prefix ? File.join(prefix, File.expand_path(dest)) : dest
      #realdest = File.join(realdest, from) #if File.dir?(realdest) #File.basename(from)) if File.dir?(realdest)

      if trace? or trial?
        #to = prefix ? File.join(prefix, dir, from) : File.join(dir, from)
        $stderr.puts "install #{dir}/#{from} #{realdest}"
      end
      return if trial?

      mkdir_p(File.direname(realdest))

      str = binread(File.join(dir, from))
      if diff?(str, realdest)
        trace_off {
          rm_f(realdest) if File.exist?(realdest)
        }
        File.open(realdest, 'wb'){ |f| f.write(str) }
        File.chmod(mode, realdest)
        #if prefix
        #  path = realdest.sub(prefix, '')
        #else
        #  path = realdest
        #end
        record_installation(realdest)
      end
    end

    # TODO: Surely this can be simplified.
    def mkdir_p(dirname) #, prefix=nil)
      #dirname = destination(dirname)
      #dirname = File.join(prefix, File.expand_path(dirname)) if prefix
      return if File.directory?(dirname)

      $stderr.puts "mkdir -p #{dirname}" if trace? or trial?

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
          Dir.mkdir path
          record_installation(path)  # also record directories made
        end
      end
    end

    #
    def record_installation(path)
      FileUtils.mkdir_p(File.dirname("#{rootdir}/#{MANIFEST}"))
      File.open("#{rootdir}/#{MANIFEST}", 'a') do |f|
        f.puts(path)
      end
    end

    #
    def destination(dir, file)
      dest = install_prefix ? File.join(install_prefix, File.expand_path(dir)) : dir
      dest = File.join(dest, file) #if File.dir?(dest)
      dest
    end

    #
    def diff?(new_content, path)
      return true unless File.exist?(path)
      new_content != binread(path)
    end

    #
    def binread(fname)
      File.open(fname, 'rb') do |f|
        return f.read
      end
    end

    # TODO: The shebang updating needs some reworking.
    # I beleive that on unix-based systems <tt>!/bin/env ruby</tt>
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

