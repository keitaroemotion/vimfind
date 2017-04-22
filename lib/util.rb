class Util
  def self.gsubs(x, kws)
    kws.split(" ").each do |kw|
      x = x.gsub(kw, kw.green)
    end
    x
  end
end  


