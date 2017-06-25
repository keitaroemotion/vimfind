require "minitest/autorun"
require "./lib/vim_find.rb"
require "./test/test_helper.rb"

class FuncSortTest < Minitest::Test
  def setup
    @fs = Lib::FuncSort
    @target_file = "./et/unko/buriburi.rb"
  end

  def test_has_terms?
    assert @fs.has_terms?("unko wa buriburi", %w(unko buriburi))
    assert @fs.has_terms?("unkoburiburi", %w(unko buriburi))
    refute @fs.has_terms?("unburiburi", %w(unko buriburi))
  end

end
 
