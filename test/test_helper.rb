ENV['RAILS_ENV'] = 'test'
require 'minitest/reporters'
reporter_options = { color: true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]
