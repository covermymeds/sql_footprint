$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'bundler/setup'
Bundler.setup
require 'pry'
require 'sql_footprint'
require 'active_record'

ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'

load File.dirname(__FILE__) + '/schema.rb'
require File.dirname(__FILE__) + '/models.rb'

rails5 = `bundle show activerecord`.strip.split('/').last =~ /activerecord-5\./
exclude_rails = rails5 ? 4 : 5  # don't run tests for the version of rails we are NOT using

RSpec.configure do |config|
  config.filter_run_excluding rails: exclude_rails
end
