def BuriBuri < Toilet
  NUM1 = "num 1" 
  NUM2 = "num 2" 
  NUM3 = "num 3" 
  def method1
    "value1"
  end

  def method2
    "value1"
  end

  def method3
    def nested_method
      "xxx"
    end
    nested_method + "x"
  end
end
