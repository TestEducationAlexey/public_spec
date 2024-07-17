# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'graphiti_spec_helpers/rspec'
require 'super_diff/rspec-rails'
require 'jsonapi/rspec'
require 'colorize'
require 'stringio'
require 'logger'

CASE_STRIO ||= StringIO.new
RSPEC_LOGGER = Logger.new CASE_STRIO
RSPEC_DEBUG_INFO = {}

Rails.application.default_url_options[:host] = "example.com"
ActiveRecord::Base.logger = RSPEC_LOGGER
ActiveRecord.verbose_query_logs = true
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end
RSpec.configure do |config|
  config.add_formatter FailuresTextFormatter
  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.after(:suite) do
    results_store = PStore.new("test_results.pstore")
    results_store.transaction do
      group = ENV["SPEC_GROUP"].to_sym
      group_data = results_store[group] || {total: 0, failed: 0, passed: 0}
      group_data[:total] = RSpec.world.example_count
      group_data[:failed] = RSpec.world.filtered_examples.values.flatten.count(&:exception)
      group_data[:passed] = group_data[:total] - group_data[:failed]
      results_store[group] = group_data
    end
  end

  config.around(:each) do |example|
    begin
      CASE_STRIO.reopen
      DatabaseCleaner.cleaning { example.run }
    ensure
      DatabaseCleaner.clean
    end
  end

  config.before :each do
    handle_request_exceptions(false)
  end

  config.after(:each) do |example|
    RSPEC_DEBUG_INFO[example.id] = CASE_STRIO.string
    CASE_STRIO.reopen
  end

  config.include Graphiti::Rails::TestHelpers
  config.include GraphitiSpecHelpers::Sugar
  config.include GraphitiSpecHelpers::RSpec
  config.include JSONAPI::RSpec
  config.include JsonHelper
  config.include ResourceHelper

  # Support for documents with mixed string/symbol keys. Disabled by default.
  config.jsonapi_indifferent_hash = true

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
