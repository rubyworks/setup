require 'setup/base'

module Setup

  #
  class Uninstaller < Base

    #
    def uninstall
      paths = File.read(INSTALL_RECORD).split("\n")
      dirs, files = paths.partition{ |f| File.dir?(f) }

      remove = []
      files.uniq.each do |file|
        next if /^\#/ =~ file  # skip comments
        remove << file if File.exist?(file)
      end

      if trace? && !trial?
        puts remove.collect{ |f| "rm #{f}" }.join("\n")
        ans = ask("Continue?", "yN")
        case ans
        when 'y', 'Y', 'yes'
        else
          return # abort?
        end
      end

      remove.each do |file|
        rm_f(file)
      end

      dirs.each do |dir|
        # okay this is over kill, but playing it safe...
        empty = Dir[File.join(dir,'*')].empty?
        begin
          if trial?
            io.puts "rmdir #{dir}"
          else
            rmdir(dir) if empty
          end
        rescue Errno::ENOTEMPTY
          io.puts "may not be empty -- #{dir}" if trace?
        end
      end

      rm_f(INSTALL_RECORD)
    end

  end

end

