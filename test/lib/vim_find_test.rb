require "minitest/autorun"
require "./lib/vim_find.rb"
require "./test/test_helper.rb"

class VimFindTest < Minitest::Test
  def setup
    @vf = VimFind.new(["foo", "bar", "./etc/files/moomin_valley"], "doubutsu_miyu")
    @aho_myoomin = "./etc/files/aho_myoomin.moo"
    @floren      = "./etc/files/moomin_valley/floren.moo"
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

  def test_has_words
    assert_equal false, @vf.has_words(%w(moomin floren ranma shampoo), "shampoo")
  end

  def test_is_term_in_file
    assert @vf.is_term_in_file(@aho_myoomin, "kakko")
    assert @vf.is_term_in_file(@aho_myoomin, ["kakko"])
    refute @vf.is_term_in_file(@aho_myoomin, ["oyaji"])
  end

  def test_includes
    assert @vf.includes(@aho_myoomin, "?kakko")
    assert @vf.includes(@aho_myoomin, "aho")
    assert @vf.includes(@aho_myoomin, ["aho", "?kakko"])
    refute @vf.includes(@aho_myoomin, ["aho", "?unko"])
    refute @vf.includes(@aho_myoomin, ["aha", "?kakko"])
  end

  def test_colorize
    text = "i have a pen. i have an apple. uhhn, apple pen?"
    terms = ["apple", "pen"]
    colorized_text = "i have a #{'pen'.green}. " \
                     "i have an #{'apple'.green}. uhhn, " \
                     "#{'apple'.green} #{'pen'.green}?"
    assert_equal colorized_text,  @vf.colorize(text, terms)
  end

  def test_list_files
    assert_equal [@aho_myoomin], @vf.list_files(@aho_myoomin, ["min"]) 
  end

  def test_display_matches 
    @vf.display_matches(@aho_myoomin, ["kakko"]) 
    @vf.display_matches(@aho_myoomin, ["kakka"]) 
  end

  def test_sort
    # TBD
  end

  def test_paint
    # TBD
  end

  def test_tmpsearch
    assert_equal ["  def manuke_moo"],  @vf.tmpsearch(@floren, "manuke")
    # TODO: this might be unexpected: the "  end" has to be trimmed later
    assert_equal ["  def baka_moo", "  end"],  @vf.tmpsearch(@floren, "baka")
  end

  # this method includes $stdin.gets
  def test_collect_funcs
    #funcs = %w(aho_moo manuke_moo iya_moo baka_moo moo_moo ansin_miyune)
    #assert_equal funcs, @vf.collect_funcs(@floren).map{|func| func.gsub("def " , "")}
  end

  def test_cf_subroutine
    res = @vf.cf_subroutine(["def oyaji", "panty", "belongs_to_unko"])  
    assert_equal ["def oyaji", "belongs_to_unko"], res
  end

  def test_get_table_name
    # TBD
  end

  def test_parse_value
    # TBD
  end

  # this method includes $stdin.gets
  def test_get_command
  end

  def test_check_db
    # TBD
  end

  # this method includes $stdin.gets
  def test_ask_no_abort
  end

  def test_ask_simple
    assert_equal "doubutsu_miyu", @vf.ask_simple("who are you?")
  end

  def test_ask
    # TBD
  end

  def test_contains
   assert @vf.contains(%w(moomin hoamumi floren), "floren")
   refute @vf.contains(%w(moomin hoamumi floren), "aaaaa")
  end

  def test_text_has
    line = "pen pine apple apple pen"
    assert @vf.text_has(%w(pine pen), line)
    refute @vf.text_has(%w(oppai pai), line)
    assert @vf.text_has(%w(oppai pen), line)
  end

  def test_share_nothing
    assert @vf.share_nothing(%w(moomin hoahoa), %w(daisuki miyu yoo))
    refute @vf.share_nothing(%w(moomin daisuki), %w(daisuki miyu yoo))
  end

  def test_survery_test
    functions = %w(moomin myoo doubutsu)
    assert_equal functions, @vf.survey_test("test/moomin/hoahoa_test.rb")
  end

  def test_unit_test
    # interactive
  end

  def test_test
    # TBD
  end

  def test_format_into_mac
    path = "oyaji(aho) noyume dakara"
    assert_equal "oyaji\\(aho\\)\\ noyume\\ dakara", @vf.format_into_mac(path)
  end
 
  def test_fix_label
    nyan = "a  nata no  koto   ga         kirai"
    assert_equal "a_nata_no_koto_ga_kirai", @vf.fix_label(nyan)
  end

  def test_is_source
    result = %w(
      ./etc/unko/moomin.rb
      ./etc/unko/a.json
      ./etc/unko/unko.js
      ./etc/unko/unko.html
      ./etc/unko/unko
      ./etc/unko/unko.unkokko
    ).map do |file|
      @vf.is_source(file)
    end
    assert_equal [true, false, true, true, false, true], result
  end

  def test_open_https
    # TBD
  end

  def test_open_test
    # TBD
  end

  def test_show_file_name
    # TBD
  end

  def test_execute_file
    # TBD
  end

  def test_execute_files
    # TBD
  end

  def test_open_file
    # TBD
  end

  def test_search_all
    # @vf.search_all TBD
  end
end  
