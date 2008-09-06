require 'rake/tasklib'

module Rake

  # Create install/uninstall tasks.
  #
  #
  class InstallTask < TaskLib
    MANIFEST = '.installedfiles'
    RBCONFIG = ::Config::CONFIG

    #
    def self.uninstallable?
      File.exist?(MANIFEST)
    end

    # Configuration. (Default is ::Config::CONFIG)
    attr_accessor :config
    attr_accessor :prefix
    attr_accessor :no_harm
    attr_accessor :without_ext

    alias_method :install_prefix, :prefix

    # Create a install task.
    def initialize(name=:install)
      @name    = name
      @config  = default_config
      @prefix  = nil
      @no_harm = false

      yield self if block_given?

      define
    end

    # Create the tasks defined by this task lib.
    def define
      desc "Install locally"
      task @name do
        exec_install
      end

      if File.exist?('.installedfiles')
        desc "Uninstall"
        task "un#{name}" do
          exec_uninstall
        end
      end

      self
    end

    # Default configuration, if none is given.
    def default_config
      prefix = RBCONFIG['prefix']

      parameterize = lambda do |key|
        path = ::Config::CONFIG[key]
        path.sub(/\A#{Regexp.quote(original_prefix)}/, '$prefix')
      end

      rubypath = File.join(RBCONFIG['bindir'], RBCONFIG['ruby_install_name'] + RBCONFIG['EXEEXT'])

      major = RBCONFIG['MAJOR'].to_i
      minor = RBCONFIG['MINOR'].to_i
      teeny = RBCONFIG['TEENY'].to_i
      version = "#{major}.#{minor}"

      # ruby ver. >= 1.4.4?
      newpath_p = ((major >= 2) or
                   ((major == 1) and
                    ((minor >= 5) or
                     ((minor == 4) and (teeny >= 4)))))

      if RBCONFIG['rubylibdir']
        # V > 1.6.3
        libruby         = "#{prefix}/lib/ruby"
        librubyver      = RBCONFIG['rubylibdir']
        librubyverarch  = RBCONFIG['archdir']
        siteruby        = RBCONFIG['sitedir']
        siterubyver     = RBCONFIG['sitelibdir']
        siterubyverarch = RBCONFIG['sitearchdir']
      elsif newpath_p
        # 1.4.4 <= V <= 1.6.3
        libruby         = "#{prefix}/lib/ruby"
        librubyver      = "#{prefix}/lib/ruby/#{version}"
        librubyverarch  = "#{prefix}/lib/ruby/#{version}/#{c['arch']}"
        siteruby        = RBCONFIG['sitedir']
        siterubyver     = "$siteruby/#{version}"
        siterubyverarch = "$siterubyver/#{RBCONFIG['arch']}"
      else
        # V < 1.4.4
        libruby         = "#{prefix}/lib/ruby"
        librubyver      = "#{prefix}/lib/ruby/#{version}"
        librubyverarch  = "#{prefix}/lib/ruby/#{version}/#{c['arch']}"
        siteruby        = "#{prefix}/lib/ruby/#{version}/site_ruby"
        siterubyver     = siteruby
        siterubyverarch = "$siterubyver/#{RBCONFIG['arch']}"
      end

      #if arg = c['configure_args'].split.detect {|arg| /--with-make-prog=/ =~ arg }
      #  makeprog = arg.sub(/'/, '').split(/=/, 2)[1]
      #else
      #  makeprog = 'make'
      #end

      parameterize = lambda {|path|
        path.sub(/\A#{Regexp.quote(prefix)}/, '$prefix')
      }

      config = []
      config['prefix']          = prefix
      config['bindir']          = parameterize['bindir']
      config['libdir']          = parameterize['libdir']
      config['datadir']         = parameterize['datadir']
      config['mandir']          = parameterize['mandir']
      config['sysconfdir']      = parameterize['sysconfdir']
      config['localstatedir']   = parameterize['localstatedir']
      config['libruby']         = libruby
      config['librubyver']      = librubyver
      config['librubyverarch']  = librubyverarch
      config['siteruby']        = siteruby
      config['siterubyver']     = siterubyver
      config['siterubyverarch'] = siterubyverarch
      config['rubypath']        = rubypath
      config['rbdir']           = '$siterubyver'
      config['sodir']           = '$siterubyverarch'
      #config['rubyprog']        = rubypath
      #config['makeprog']        = makeprog

      return config
    end

    #
    def lookup(name)
      config[key].gsub(%r<\$([^/]+)>){ config[$1] }
    end

    #
    # Uninstall
    #

    def exec_uninstall
      files = File.read('.installedfiles').split("\n")
      files.each do |f|
        next if f =~ /^\#/  # ignore comment lines
        next if f =~ /\S/   # ignore if blank
        if File.exist?(f)
          FileUtils.rm_f(f)
        end
      end
    end

    #
    # Installation procedure
    #

    def exec_install
      #rm_f "#{INSTALLED_MANIFEST}"
      exec_task_traverse 'install'
    end

    def install_dir_bin(rel)
      install_files targetfiles(), "#{lookup('bindir')}/#{rel}", 0755
    end

    def install_dir_lib(rel)
      install_files libfiles(), "#{lookup('rbdir')}/#{rel}", 0644
    end

    def install_dir_ext(rel)
      return unless extdir?(curr_srcdir())
      install_files rubyextentions('.'), "#{lookup('sodir')}/#{File.dirname(rel)}", 0555
    end

    def install_dir_data(rel)
      install_files targetfiles(), "#{lookup('datadir')}/#{rel}", 0644
    end

    def install_dir_conf(rel)
      # FIXME: should not remove current config files
      # (rename previous file to .old/.org)
      install_files targetfiles(), "#{lookup('sysconfdir')}/#{rel}", 0644
    end

    def install_dir_man(rel)
      install_files targetfiles(), "#{lookup('mandir')}/#{rel}", 0644
    end

    def install_files(list, dest, mode)
      mkdir_p dest, install_prefix
      list.each do |fname|
        install fname, dest, mode, install_prefix
      end
    end

    def libfiles
      glob_reject(%w(*.y *.output), targetfiles())
    end

    def rubyextentions(dir)
      ents = glob_select("*.#{dllext}", targetfiles())
      if ents.empty?
        setup_rb_error "no ruby extention exists: 'ruby #{$0} setup' first"
      end
      ents
    end

    def dllext
      ::Config::CONFIG['DLEXT']
    end

    def targetfiles
      mapdir(existfiles() - hookfiles())
    end

    def mapdir(ents)
      ents.map {|ent|
        if File.exist?(ent)
        then ent                         # objdir
        else "#{curr_srcdir()}/#{ent}"   # srcdir
        end
      }
    end

    # picked up many entries from cvs-1.11.1/src/ignore.c
    JUNK_FILES = %w(
      core RCSLOG tags TAGS .make.state
      .nse_depinfo #* .#* cvslog.* ,* .del-* *.olb
      *~ *.old *.bak *.BAK *.orig *.rej _$* *$

      *.org *.in .*
    )

    def existfiles
      glob_reject(JUNK_FILES, (files_of(curr_srcdir()) | files_of('.')))
    end

    def hookfiles
      %w( pre-%s post-%s pre-%s.rb post-%s.rb ).map {|fmt|
        %w( config setup install clean ).map {|t| sprintf(fmt, t) }
      }.flatten
    end

    def glob_select(pat, ents)
      re = globs2re([pat])
      ents.select {|ent| re =~ ent }
    end

    def glob_reject(pats, ents)
      re = globs2re(pats)
      ents.reject {|ent| re =~ ent }
    end

    GLOB2REGEX = {
      '.' => '\.',
      '$' => '\$',
      '#' => '\#',
      '*' => '.*'
    }

    def globs2re(pats)
      /\A(?:#{
        pats.map {|pat| pat.gsub(/[\.\$\#\*]/) {|ch| GLOB2REGEX[ch] } }.join('|')
      })\z/
    end

    #
    # Traversing
    #

    def exec_task_traverse(task)
      run_hook "pre-#{task}"
      FILETYPES.each do |type|
        if type == 'ext' and without_ext
          $stderr.puts 'skipping ext/* by user option' if verbose?
          next
        end
        traverse task, type, "#{task}_dir_#{type}"
      end
      run_hook "post-#{task}"
    end

    def traverse(task, rel, mid)
      dive_into(rel) {
        run_hook "pre-#{task}"
        __send__ mid, rel.sub(%r[\A.*?(?:/|\z)], '')
        directories_of(curr_srcdir()).each do |d|
          traverse task, "#{rel}/#{d}", mid
        end
        run_hook "post-#{task}"
      }
    end

    def dive_into(rel)
      return unless File.dir?("#{@srcdir}/#{rel}")

      dir = File.basename(rel)
      Dir.mkdir dir unless File.dir?(dir)
      prevdir = Dir.pwd
      Dir.chdir dir
      $stderr.puts '---> ' + rel if verbose?
      @currdir = rel
      yield
      Dir.chdir prevdir
      $stderr.puts '<--- ' + rel if verbose?
      @currdir = File.dirname(rel)
    end

    def run_hook(id)
      path = [ "#{curr_srcdir()}/#{id}",
               "#{curr_srcdir()}/#{id}.rb" ].detect {|cand| File.file?(cand) }
      return unless path
      begin
        instance_eval File.read(path), path, 1
      rescue
        raise if $DEBUG
        setup_rb_error "hook #{path} failed:\n" + $!.message
      end
    end

    #
    # File Operations
    #

    def mkdir_p(dirname, prefix = nil)
      dirname = prefix + File.expand_path(dirname) if prefix
      $stderr.puts "mkdir -p #{dirname}" if verbose?
      return if no_harm?

      # Does not check '/', it's too abnormal.
      dirs = File.expand_path(dirname).split(%r<(?=/)>)
      if /\A[a-z]:\z/i =~ dirs[0]
        disk = dirs.shift
        dirs[0] = disk + dirs[0]
      end
      dirs.each_index do |idx|
        path = dirs[0..idx].join('')
        Dir.mkdir path unless File.dir?(path)
      end
    end

    def rm_f(path)
      $stderr.puts "rm -f #{path}" if verbose?
      return if no_harm?
      force_remove_file path
    end

    def rm_rf(path)
      $stderr.puts "rm -rf #{path}" if verbose?
      return if no_harm?
      remove_tree path
    end

    def remove_tree(path)
      if File.symlink?(path)
        remove_file path
      elsif File.dir?(path)
        remove_tree0 path
      else
        force_remove_file path
      end
    end

    def remove_tree0(path)
      Dir.foreach(path) do |ent|
        next if ent == '.'
        next if ent == '..'
        entpath = "#{path}/#{ent}"
        if File.symlink?(entpath)
          remove_file entpath
        elsif File.dir?(entpath)
          remove_tree0 entpath
        else
          force_remove_file entpath
        end
      end
      begin
        Dir.rmdir path
      rescue Errno::ENOTEMPTY
        # directory may not be empty
      end
    end

    def move_file(src, dest)
      force_remove_file dest
      begin
        File.rename src, dest
      rescue
        File.open(dest, 'wb') {|f|
          f.write File.binread(src)
        }
        File.chmod File.stat(src).mode, dest
        File.unlink src
      end
    end

    def force_remove_file(path)
      begin
        remove_file path
      rescue
      end
    end

    def remove_file(path)
      File.chmod 0777, path
      File.unlink path
    end

    def install(from, dest, mode, prefix = nil)
      $stderr.puts "install #{from} #{dest}" if verbose?
      return if no_harm?

      realdest = prefix ? prefix + File.expand_path(dest) : dest
      realdest = File.join(realdest, File.basename(from)) if File.dir?(realdest)
      str = File.binread(from)
      if diff?(str, realdest)
        verbose_off {
          rm_f realdest if File.exist?(realdest)
        }
        File.open(realdest, 'wb') {|f|
          f.write str
        }
        File.chmod mode, realdest

        File.open("#{objdir_root()}/#{INSTALLED_MANIFEST}", 'a') {|f|
          if prefix
            f.puts realdest.sub(prefix, '')
          else
            f.puts realdest
          end
        }
      end
    end

    def diff?(new_content, path)
      return true unless File.exist?(path)
      new_content != File.binread(path)
    end

    def command(*args)
      $stderr.puts args.join(' ') if verbose?
      system(*args) or raise RuntimeError,
          "system(#{args.map{|a| a.inspect }.join(' ')}) failed"
    end

    #def ruby(*args)
    #  command lookup('rubyprog'), *args
    #end

    #def make(task = nil)
    #  command(*[lookup('makeprog'), task].compact)
    #end

    def extdir?(dir)
      File.exist?("#{dir}/MANIFEST") or File.exist?("#{dir}/extconf.rb")
    end

    def files_of(dir)
      Dir.open(dir) {|d|
        return d.select {|ent| File.file?("#{dir}/#{ent}") }
      }
    end

    DIR_REJECT = %w( . .. CVS SCCS RCS CVS.adm .svn )

    def directories_of(dir)
      Dir.open(dir) {|d|
        return d.select {|ent| File.dir?("#{dir}/#{ent}") } - DIR_REJECT
      }
    end

    #
    # Hook API
    #

    # NOTE: Pretty sure this is right.
    def srcdir_root
      @ardir ||= File.expand_path('.')
    end

    def objdir_root
      '.'
    end

    def relpath
      '.'
    end

    #def get_config(key)
    #  @config[key]
    #end
    #alias config get_config

    # obsolete: use metaconfig to change configuration
    #def set_config(key, val)
    #  @config[key] = val
    #end

    #
    # srcdir/objdir (works only in the package directory)
    #

    def curr_srcdir
      "#{srcdir_root()}/#{relpath()}"
    end

    def curr_objdir
      "#{objdir_root()}/#{relpath()}"
    end

    def srcfile(path)
      "#{curr_srcdir()}/#{path}"
    end

    def srcexist?(path)
      File.exist?(srcfile(path))
    end

    def srcdirectory?(path)
      File.dir?(srcfile(path))
    end

    def srcfile?(path)
      File.file?(srcfile(path))
    end

    def srcentries(path = '.')
      Dir.open("#{curr_srcdir()}/#{path}") {|d|
        return d.to_a - %w(. ..)
      }
    end

    def srcfiles(path = '.')
      srcentries(path).select {|fname|
        File.file?(File.join(curr_srcdir(), path, fname))
      }
    end

    def srcdirectories(path = '.')
      srcentries(path).select {|fname|
        File.dir?(File.join(curr_srcdir(), path, fname))
      }
    end

  end

end

