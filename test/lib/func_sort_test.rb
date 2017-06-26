require "minitest/autorun"
require "./lib/vim_find.rb"
require "./test/test_helper.rb"

class FuncSortTest < Minitest::Test
  def setup
    @fs = Lib::FuncSort
    @target_file = "./etc/unko/buriburi.rb"
    @klass_str = """
module Unko    
  def Class < AAA
    BBB = \"bbb\"
    CCC = \"vvv\"

    def brother 
      xxx
    end
    def clean
      yyy
    end
    def apple 
      zzz
    end

    private

    def dog 
      1
    end
    def ass 
      0
    end
  end
end  
    """.split("\n")
  end

  def test_has_terms?
    assert @fs.has_terms?("unko wa buriburi", %w(unko buriburi))
    assert @fs.has_terms?("unkoburiburi", %w(unko buriburi))
    refute @fs.has_terms?("unburiburi", %w(unko buriburi))
  end

  def test_private_array
    lines = File.open(@target_file, "r").to_a
    private_array = [
      "def pinch_nipple1",
      "\"oh!\"",
      "end",
      "",
      "def pinch_nipple2",
      "xxxx",
      "",
      "yyy",
      "\"ooo!\"",
      "end",
      "",
      "def pinch_nipple3",
      "\"oh God!\"",
      "end",
      "end"
    ]
    assert_equal private_array, @fs.private_array(lines, 0)
  end

  def test_public_array
    lines = File.open(@target_file, "r").to_a
    public_array = [
      "def Buri",
    ]
    #assert_equal public_array, @fs.private_array(lines, 0, true)
  end

  def maximum(lines)
    lines.select do |line|
       /\s*def.*/
        .match(line)
    end.map do |line|
      line.split("def ")[0].size
    end.max
  end

  def method_indents(klass_str)
    " ".rjust(maximum(@klass_str))
  end

  def methods(lines)
    indents = method_indents(lines)

    flag = false
    target      = []
    targets     = []
    non_targets = []

    lines.each do |line| 
      if /^#{indents}def\s.*/.match(line)
        flag = true
        target.push "\n"+line
      elsif /#{indents}end.*/.match(line)
        flag = false
        targets.push target
        target = []
      elsif flag
        target.push line
      else
        non_targets.push line
      end
    end 

    targets = targets.map do |target|
      target + ["#{indents}end"]
    end

    [targets.sort, non_targets]
  end

  def private_defs(lines)
    _lines = []
    flag = true
    lines.reverse.each do |line|
      if line.strip == "private"
        flag = false 
      end
      _lines.push(line) if flag
    end
    
    _lines.select do |line|
      /(def|module|class)\s.*/.match(line.strip)
    end
  end

  def include?(arr, x)
    arr.select do |a|
      x[0].include?(a)
    end.size > 0
  end

  def get_methods(str, is_public)
    methods(str)[0]
      .select do |x| 
         included = include?(private_defs(str), x)
         is_public ? !included : included
      end
  end

  def test_defs
    defs = @fs.defs(@klass_str)
    assert_equal 7,   defs.size
    indents = method_indents(defs)
    assert_equal "    ", indents 

    pub_methods = get_methods(@klass_str, true)
    pri_methods = get_methods(@klass_str, false)

    assert_equal """
    def apple 
      zzz
    end

    def brother 
      xxx
    end

    def clean
      yyy
    end""",  pub_methods.join("\n")  
    assert_equal """
    def ass 
      0
    end

    def dog 
      1
    end""",  pri_methods.join("\n")
  end

  def test_sort_top_methods
  end
end
 
