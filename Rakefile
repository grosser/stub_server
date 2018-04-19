# frozen_string_literal: true
require "bundler/setup"
require "bundler/gem_tasks"
require "bump/tasks"
require "rake/testtask"
require "wwtd/tasks"

task default: [:test, :rubocop]

Rake::TestTask.new :test do |t|
  t.pattern = 'test/**/*_test.rb'
  t.warning = true
end

desc "Run rubocop"
task :rubocop do
  sh "rubocop"
end
