require "minitest/autorun"
require "./lib/vim_find.rb"
require "./test/test_helper.rb"

class FuncSortTest < Minitest::Test
  def setup
    @fs = Lib::FuncSort
    @target_file = "./etc/unko/buriburi.rb"
    @klass_str = 
"""module Unko    
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

    @klass_str2 = 
"""
module Oppai
  module Unko    
    class Class < AAA
      BBB = \"bbb\"
      CCC = \"vvv\"

      def brother 
        ass.do |x|
          oppai
        end
        xxx
      end
      def clean
        ass.do |x|
          xxx.do |y|
            zzz
          end
        end
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

  def test_indents
    indents = @fs.method_indents(@fs.defs(@klass_str))
    assert_equal "    ", indents 
  end

  def test_defs
    defs = @fs.defs(@klass_str)
    assert_equal 7,   defs.size
  end

  def test_defs
    sorted_class = @fs.sort_class(@klass_str).split("\n")
"""module Unko
  def Class < AAA
    BBB = \"bbb\"
    CCC = \"vvv\"

    def apple
      zzz
    end

    def brother
      xxx
    end

    def clean
      yyy
    end

    private

    def ass
      0
    end

    def dog
      1
    end

  end
end""".split("\n").each_with_index do |line, i|
      assert_equal line, sorted_class[i]
    end
  end

  def test_defs
    sorted_class = @fs.sort_class(@klass_str2).split("\n")
"""
module Oppai
  module Unko
    class Class < AAA
      BBB = \"bbb\"
      CCC = \"vvv\"

      def apple
        zzz
      end

      def brother
        ass.do |x|
          oppai
        end
        xxx
      end

      def clean
        ass.do |x|
          xxx.do |y|
            zzz
          end
        end
        yyy
      end

      private

      def ass
        0
      end

      def dog
        1
      end

    end
  end
end""".split("\n").each_with_index do |line, i|
      assert_equal line, sorted_class[i]
    end
  end


  def test_sort_top_methods
  end
end
 
