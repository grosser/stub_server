# frozen_string_literal: true
require "bundler/setup"
require "bundler/gem_tasks"
require "bump/tasks"

task :default do
  sh "rspec spec/ && rubocop"
end
