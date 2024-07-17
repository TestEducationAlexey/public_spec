require "fileutils"
require 'rspec/core'
require 'pstore'

APP_ROOT = File.expand_path("..", __dir__)

FileUtils.chdir APP_ROOT do
  results_file = "test_results.pstore"

  if File.exist?(results_file)
    File.delete(results_file)
  end

  results_store = PStore.new(results_file)
  results_store.transaction do
    results_store[:initialized] = true # Инициализируем хранилище
  end

  groups = [:base_create, :base_update, :advanced, :anomalies]

  groups.each_with_index do |group, index|
    files = Dir.glob("spec/api/v1/#{group}/**/*_spec.rb")

    break if files.empty?

    command = "SPEC_GROUP=#{group} bundle exec rspec #{Shellwords.join(files)}"

    puts "Running: lvl #{index + 1}"
    system(command)

    break unless $?.success?
  end

  results_store = PStore.new("test_results.pstore")
  results_store.transaction(true) do
    results_store.roots.each do |group|
      puts "Results for #{group}:"
      p results_store[group]
    end
  end
end