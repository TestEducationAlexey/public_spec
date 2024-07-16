require 'rspec/core/formatters/progress_formatter'
require 'rspec/core/formatters'

class FailuresTextFormatter < RSpec::Core::Formatters::ProgressFormatter
  ::RSpec::Core::Formatters.register self, :dump_failures

  def dump_failures(notification)
    formatted = "\nFailures:\n"
    notification.failure_notifications.each_with_index do |failure, index|
      formatted += failure.fully_formatted(index.next, ::RSpec::Core::Formatters::ConsoleCodes)
      formatted += RSPEC_DEBUG_INFO[failure.example.id]
    end

    output.puts formatted
  end
end
