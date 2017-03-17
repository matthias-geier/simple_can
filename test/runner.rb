require "simple_can"
require "minitest/spec"
require "minitest/autorun"

SimpleCan.strategy = SimpleCan::BasicStrategy
describe "suite" do
  before do
    SimpleCan.strategy = SimpleCan::BasicStrategy
  end

  Dir["**/*_test.rb"].shuffle.each { |f| load f }
end
