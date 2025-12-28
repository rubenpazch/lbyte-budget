# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]

desc 'Run tests and open coverage report'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].invoke
  `open coverage/index.html` if RUBY_PLATFORM =~ /darwin/
end
