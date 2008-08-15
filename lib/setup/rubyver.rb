#
# Ruby Extensions
#

unless File.respond_to?(:read)   # Ruby 1.6 and less
  def File.read(fname)
    open(fname) {|f|
      return f.read
    }
  end
end

unless Errno.const_defined?(:ENOTEMPTY)   # Windows?
  module Errno
    class ENOTEMPTY
      # We do not raise this exception, implementation is not needed.
    end
  end
end

# for corrupted Windows' stat(2)
def File.dir?(path)
  File.directory?((path[-1,1] == '/') ? path : path + '/')
end

