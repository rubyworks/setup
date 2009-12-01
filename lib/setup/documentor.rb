require 'setup/base'

module Setup

  #
  class Documentor < Base

    #
    def document
      return if config.no_doc
      exec_ri

      #if file = DOCSCRIPT
      #  ruby(file)
      #else
      #  exec_rdoc
      #end
    end

    # Generate ri documentation.
    #++
    # TODO: call rdoc programmatically.
    #--
    def exec_ri
      case config.type #installdirs
      when 'std', 'ruby'
        output = "--ri-system"
      when 'site'
        output = "--ri-site"
      when 'home'
        output = "--ri"
      else
        abort "bad config: should not be possible -- type=#{config.type}"
      end

      if File.exist?('.document')
        files = File.read('.document').split("\n")
        files.reject!{ |l| l =~ /^\s*[#]/ || l !~ /\S/ }
        files.collect!{ |f| f.strip }
      #elsif File.exist?('meta/loadpath')
      else
        files = []
        files << 'lib' if File.directory?('lib')
        files << 'ext' if File.directory?('ext')
      end

      opt = []
      opt << "-U"
      opt << "-q" #if quiet?
      #opt << "-D" #if $DEBUG
      opt << output
      opt << files

      opt = opt.flatten

      cmd = "rdoc " + opt.join(' ')

      if trial?
        puts cmd
      else
        begin
          system(cmd)
          #require 'rdoc/rdoc'
          #::RDoc::RDoc.new.document(opt)
          io.puts "Ok ri." #unless quiet?
        rescue Exception
          $stderr.puts "ri generation failed"
          $stderr.puts "command was: '#{cmd}'"
          $stderr.puts "proceeding with install..."
        end

        # Now in local directory
        #opt = []
        #opt << "-U"
        #opt << "--ri --op 'doc/ri'"
        #opt << files
        #opt = opt.flatten
        #::RDoc::RDoc.new.document(opt)
      end
    end

    # Generate rdocs.
    #
    # Needs <tt>meta/name</tt> or <tt>.meta/name</tt>.
    #
    # NOTE: This is not being used. It's here in case we decide
    # to add this feature, though it is quite possible that
    # we may never do so.
    #
    def exec_rdoc
      main = Dir.glob("README{,.*}", File::FNM_CASEFOLD).first

      if File.exist?('.document')
        files = File.read('.document').split("\n")
        files.reject!{ |l| l =~ /^\s*[#]/ || l !~ /\S/ }
        files.collect!{ |f| f.strip }
      else
        files = []
        files << main  if main
        files << 'lib' if File.directory?('lib')
        files << 'ext' if File.directory?('ext')
      end

      checkfiles = (files + files.map{ |f| Dir[File.join(f,'*','**')] }).flatten.uniq
      if FileUtils.uptodate?('doc/rdoc', checkfiles)
        puts "RDocs look current."
        return
      end

      output    = 'doc/rdoc'
      title     = (PACKAGE.capitalize + " API").strip if PACKAGE
      template  = config.doctemplate || 'html'

      opt = []
      opt << "-U"
      opt << "-q" #if quiet?
      opt << "--op=#{output}"
      #opt << "--template=#{template}"
      opt << "--title=#{title}"
      opt << "--main=#{main}"     if main
      #opt << "--debug"
      opt << files

      opt = opt.flatten

      cmd = "rdoc " + opt.join(' ')

      if trial?
        puts cmd 
      else
        begin
          system(cmd)
          #require 'rdoc/rdoc'
          #::RDoc::RDoc.new.document(opt)
          puts "Ok rdoc." unless quiet?
        rescue Exception
          puts "Fail rdoc."
          puts "Command was: '#{cmd}'"
          puts "Proceeding with install anyway."
        end
      end
    end

  end

end

