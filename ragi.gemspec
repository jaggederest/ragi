require "rubygems"
require "rake"

spec = Gem::Specification.new do |gem|
   gem.name        = "ragi"
   gem.version     = "1.0.2"
   gem.author      = "Joe Heitzeberg"
   gem.email       = "joe_AT_snapvine.com"
   gem.homepage    = "http://rubyforge.org/projects/ragi"
   gem.platform    = Gem::Platform::RUBY
   gem.summary     = "RAGI allows you to create useful telephony applications using Asterisk and Ruby [on Rails]."
   gem.description = "RAGI allows you to create useful telephony applications using Asterisk and Ruby [on Rails].  Please see the included README file for more information"
   gem.has_rdoc    = false
   gem.require_paths = [".", "ragi"]
   gem.files = FileList['example-call-audio.mp3', 'CHANGELOG',
    'README', 'ragi/*.rb', 'RAGI Overview_files/*',
    'sample-apps/simon/*.rb', 'sample-apps/simon/sounds/README',
    'sample-apps/simon/sounds/*.gsm', 'agi-bin/*'].to_a
   gem.files.reject! { |fn| fn.include? "SVN" } 
end

if $0 == __FILE__
   Gem.manage_gems
   Gem::Builder.new(spec).build
end

