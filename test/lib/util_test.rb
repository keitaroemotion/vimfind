require "minitest/autorun"
require "./lib/util.rb"
require "./test/test_helper.rb"
require "colorize"

class UtilTest < MiniTest::Test
  def setup
    @util = Util 
  end
    
  def test_paint
    assert_equal "./lib/" + "uti".green + "l.rb", @util.paint(%w[uti], "./lib/util.rb")
    expectation = [
      "./", 
      "li".green,
      "b/",
      "uti".green,
      "l.rb",
    ].join  
    assert_equal expectation,                     @util.paint(%w[li uti], "./lib/util.rb")
    assert_equal "./lib/utilaa.rb".red,           @util.paint(%w[uti], "./lib/utilaa.rb")
  end

  def test_sort_kws
  end
end
 
