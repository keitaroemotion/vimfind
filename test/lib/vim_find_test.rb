require "minitest/autorun"
require "./lib/vim_find.rb"
require "./test/test_helper.rb"

class VimFindTest < Minitest::Test
  def setup
    @vf = VimFind.new(["foo", "bar"])
  end

  def test_random_param_is_okay
    VimFind.new(["foo"])
  end

  def test_do_arg_input_is_okay
    VimFind.new(["-do"])
  end

  def test_virtual_path
    assert_equal "/usr/local/etc/vf/virtual_branch",  @vf.virtual_path
  end

  def test_virtual_branch
    if File.exist?(@vf.virtual_path)
      refute @vf.virtual_branch.nil?
    end
  end

  def test_virtual_files
    # TBD
  end

  def test_set_virtual
    # TBD
  end

  def test_refer
    # TBD
  end

  def test_option
    assert_equal "foo", @vf.option
  end

  def test_first_arg
    assert_equal "bar", @vf.first_arg
  end


end  
