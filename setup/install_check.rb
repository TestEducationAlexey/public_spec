require "fileutils"

APP_ROOT = File.expand_path("..", __dir__)

def system!(*args)
  system(*args) || abort("\n== Command #{args} failed ==")
end

def prepare_gemfile
  content = File.read('./Gemfile')

  content.gsub!(/^group.*:test.*do\n(.*\n)*?end/m, '')

  content.gsub!(/^gem\s+["'](rspec.*|.*spec|faker.*)["'].*\n/, '')
  new_gems = File.read('./setup/Gemfile.new')

  content << "\n" unless content.end_with?("\n")

  content << new_gems

  File.write('./Gemfile', content)
end

FileUtils.chdir APP_ROOT do
  puts "== Update gemfile =="
  prepare_gemfile

  # puts "== Installing dependencies =="
  # system! "gem install bundler --conservative"
  # system!("bundle install")
end
