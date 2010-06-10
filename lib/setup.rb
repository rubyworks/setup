require 'yaml'

module Setup
  DIRECTORY = File.dirname(__FILE__) + '/setup'

  PROFILE = YAML.load(File.new(DIRECTORY + '/profile.yml'))
  verfile = YAML.load(File.new(DIRECTORY + '/version.yml'))

  VERSION = verfile.values_at('major','minor','patch','state','build').compact.join('.')

  #
  def self.const_missing(name)
    key = name.to_s.downcase
    if verfile.key?(key)
      verfile[key]
    elsif profile.key?(key)
      PROFILE[key]
    else
      super(name)
    end
  end
end

require 'setup/session'

