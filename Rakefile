#!/usr/bin/env rake
require 'bundler/gem_tasks'
require 'rake/testtask'

task :default => [:test]

desc 'Run all tests'
Rake::TestTask.new(:test) { |t|
  t.libs << 'lib'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
  t.warning = true
}