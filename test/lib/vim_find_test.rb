require "minitest/autorun"
require "./lib/vim_find.rb"
require "./test/test_helper.rb"

class VimFindTest < Minitest::Test
  def setup
    @vf = VimFind.new(["foo", "bar", "./etc/files/moomin_valley"])
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

  def test_disp_instruction
    # TBD 
  end

  def test_add_test
    files = %w(
      app/moomin/daisuki/hoahoa.rb
      app/moomin/daisuki/manuke.rb
      app/controller/template.rb
      lib/hoahoa/moomoo.rb
    )
    test_files = %w(
      test/app/moomin/daisuki/hoahoa.rb
      test/app/moomin/daisuki/manuke.rb
      test/app/controller/template.rb
      test/lib/hoahoa/moomoo.rb   
    )
    assert_equal files + test_files, @vf.add_test(files) 
  end

  def test_terms
    assert_equal ["foo", "bar", "./etc/files/moomin_valley"], @vf.terms
  end

  def test_get_directory_when_params_have_directory
    assert_equal "./etc/files/moomin_valley", @vf.get_directory
  end

  def test_get_directory_when_params_does_not_have_directory
    @vf = VimFind.new(["foo", "bar", "./etc/fake_dir/"])
    assert_equal Dir.pwd, @vf.get_directory
  end

  def test_directory
    assert_equal "./etc/files/moomin_valley/**/*", @vf.directory
  end

  def test_file_open
    content = "boku wa moomin miyu yooh\nkakko heart\n"
    assert_equal content, @vf.file_open("./etc/files/aho_myoomin.moo", "r")
  end

  def test_get_words
    list = %w(moomin miyu ahomumi)
    assert_equal list, @vf.get_words(["?moomin", "floren", "?miyu", "?ahomumi"]) 
  end

  def test_get_words_never_fails
    assert_equal [], @vf.get_words(["moomin", "floren", "mi?yu", "ahomumi?"]) 
  end

  def test_get_non_words
    res = @vf.get_non_words(%w(aho miyu ?moo ?myoo ?moomi ?moooo ?iyamumi ?hoammumi))
    assert_equal %w(aho miyu), res
  end

  def test_get_non_words_never_fails
    res = @vf.get_non_words(%w(?moo ?myoo ?moomi ?moooo ?iyamumi ?hoammumi))
    assert_equal [], res
  end
end  
