require 'setup/base'

module Setup

  # TODO: It would be nice to improve this such that
  # files to be removed are taken out of the list of
  # directories that may be removed when they become
  # empty. That way the end-user can see an exact list
  # before commiting to the uninstall (using --force).
  #
  class Uninstaller < Base

    #
    def uninstall
      return unless File.exist?(INSTALL_RECORD)

      files = []
      dirs  = []

      paths.each do |path|
        dirs  << path if File.dir?(path)
        files << path if File.file?(path)
      end

      if dirs.empty? && files.empty?
        io.outs "Nothing to remove."
        return
      end

      files.sort!{ |a,b| b.size <=> a.size }
      dirs.sort!{ |a,b| b.size <=> a.size }

      if !force? && !trial?
        puts (files + dirs).collect{ |f| "#{f}" }.join("\n")
        puts
        puts "Must use --force option to remove these files and directories that become empty."
        return
      end

      files.each do |file|
        rm_f(file)
      end

      dirs.each do |dir|
        entries = Dir.entries(dir)
        entries.delete('.')
        entries.delete('..')

        #begin
          rmdir(dir) if entries.empty?
        #rescue Errno::ENOTEMPTY
        #  io.puts "not empty -- #{dir}"
        #end
      end

      rm_f(INSTALL_RECORD)
    end

  private

    # path list from install record
    def paths
      @paths ||= (
        lines = File.read(INSTALL_RECORD).split(/\s*\n/)
        lines = lines.map{ |line| line.strip }
        lines = lines.uniq
        lines = lines.reject{ |line| line.empty? }       # skip blank lines
        lines = lines.reject{ |line| line[0,1] == '#' }  # skip blank lines
        lines
      )
    end

  end

end

