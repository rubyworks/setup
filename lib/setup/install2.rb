module Setup

  # Installer class handles the actual install procedure,
  # as well as the other tasks, such as testing.
  #
  # THIS IS A WORK IN PROGRESS REWRITE.
  #
  # This version will no support per-directory hooks.
  #
  class Installer
    MANIFEST  = '.cache/setup/installedfiles'
    FILETYPES = %w( bin lib ext data etc man doc )

    # Install package.
    def install
      install_bin
      install_lib
      install_data
      install_etc
      install_man
      install_doc
    end

    # Install binaries (executables).
    def install_bin
      files = files('bin')
      install_files files, config.bindir, 0755
    end

    # Install shared extension libraries.
    def install_ext
      files = files('ext')
      files = files.select{ |f| File.fnmatch?(File.basename(f), "*.#{dllext}") }
      install_files files, config.sodir, 0555
    end

    # Install library files.
    def install_lib
      files = files('lib')
      install_files files, config.rbdir, 0644
    end

    # Install shared data.
    def install_data
      files = files('data')
      install_files files, config.datadir, 0644
    end

    # Install configuration.
    def install_etc
      files = files('etc')
      install_files files, config.sysconfdir, 0644
    end

    # Install manpages.
    def install_man
      files = files('man')
      install_files files, config.mandir, 0644
    end

    # Install documentation.
    def install_doc
      files = files('doc')
      install_files files, config.docdir, 0644
    end

    private

    #
    def files(dir)
      files = Dir["#{dir}/**/*"]
      files = files.select{ |f| File.file?(f) }
      files = files.map{ |f| f.sub("#{dir}/", '') }
      files
    end

    #
    def install_files(list, dest, mode)
      mkdir_p dest, install_prefix
      list.each do |fname|
        install fname, dest, mode, install_prefix
      end
    end

    #
    def install(from, dest, mode, prefix = nil)
      $stderr.puts "install #{from} #{dest}" if verbose?
      return if dryrun?

      realdest = prefix ? prefix + File.expand_path(dest) : dest
      realdest = File.join(realdest, File.basename(from)) if File.dir?(realdest)
      str = binread(from)
      if diff?(str, realdest)
        verbose_off {
          rm_f realdest if File.exist?(realdest)
        }
        File.open(realdest, 'wb') {|f|
          f.write str
        }
        File.chmod mode, realdest
        if prefix
          path = realdest.sub(prefix, '')
        else
          path = realdest
        end
        record_installation(path)
      end
    end

    # TODO: Surely this can be simplified.
    def mkdir_p(dirname, prefix=nil)
      dirname = prefix + File.expand_path(dirname) if prefix
      $stderr.puts "mkdir -p #{dirname}" if verbose?
      return if dryrun?

      # Does not check '/', it's too abnormal.
      dirs = File.expand_path(dirname).split(%r<(?=/)>)
      if /\A[a-z]:\z/i =~ dirs[0]
        disk = dirs.shift
        dirs[0] = disk + dirs[0]
      end
      dirs.each_index do |idx|
        path = dirs[0..idx].join('')
        Dir.mkdir path unless File.dir?(path)
        record_installation(path)  # also record directories made
      end
    end

    #
    def record_installation(path)
      FileUtils.mkdir_p(File.dirname("#{objdir_root()}/#{MANIFEST}"))
      File.open("#{objdir_root()}/#{MANIFEST}", 'a') do |f|
        f.puts(path)
      end
    end

    #
    def diff?(new_content, path)
      return true unless File.exist?(path)
      new_content != binread(path)
    end

    #
    def rubyextentions(dir)
      ents = glob_select("*.#{dllext}", targetfiles())
      if ents.empty?
        setup_rb_error "no ruby extention exists: 'ruby #{$0} setup' first"
      end
      ents
    end

    #
    def dllext
      ConfigTable::RBCONFIG['DLEXT']
    end

  end

end

