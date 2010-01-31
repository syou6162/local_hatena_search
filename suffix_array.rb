class Array
  def bsearch(key, left = 0, right = self.size - 1, &comp)
    return -1 if left > right
    mid = (left + right) / 2
    case comp.call(mid)
    when 0
      mid
    when -1
      bsearch(key, mid + 1, right, &comp)
    else
      bsearch(key, left, mid - 1, &comp)
    end
  end
end

class SuffixArray
  attr_reader :word
  def initialize(word)
    @word = word
    @sary = Array.new(@word.size){|i| i }
    @sary.sort! do |i, j|
      @word[i .. -1] <=> @word[j .. -1]
    end
  end

  def search(key)
    i = @sary.bsearch(key) do |mid|
      @word[@sary[mid], key.size] <=> key
    end
    (i >= 0) ? @sary[i] : -1
  end
end
