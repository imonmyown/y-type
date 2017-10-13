require "yaml"

class Array(T)
  def normalize
    max = self.max
    self.map {|x| x.to_f / max }
  end

  def denormalize
    min = self.min
    self.map {|x| (x / min).round.to_i }
  end

  def update(other, weight = 1)
    a = self.normalize
    # fill zeroes in updated frequencies by original values
    b = a.zip(other).map {|x, y| y == 0.0 ? x : y }
    puts a
    puts b
    # produce a weighted average
    result = a.zip(b) {|x, y| (x + weight*y) / (1 + weight) }
    puts result
    result
  end
end

class Generator
  @chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890~`!@#$%^&*()_-+={}[]|\\;:\'\"<>,.?/"
  @config : String
  @bumps : Array({Float64, Int32})
  @char_index : Hash(Char, Int32)
  @@generator : Generator?

  def initialize
    # Initialize the array of frequency 'bumps' for individual chars
    @char_index = Hash.zip(@chars.chars.to_a, (0...@chars.size).to_a)
    @bumps = Array.new(@chars.size, {0.0, 0})
    # TODO: move to config
    dir = "#{ENV["HOME"]}/.y-type"
    Dir.mkdir(dir) unless Dir.exists?(dir)
    @config = dir + "/frequency.yaml"

    if File.exists?(@config) && !File.empty?(@config)
      @freqs = Array(Float32).from_yaml(File.read(@config)).denormalize
    else
      @freqs = Array(Int32).new(@chars.size, 1)
      File.write(@config, @freqs.normalize)
    end
  end

  def update_stats
    # average the frequency bumps
    puts @bumps
    bumps = @bumps.map {|f, n| n == 0 ? 0.0 : f / n }
    File.write(@config, @freqs.update(bumps))
  end

  def generate(len) : String
    String.build(len) {|s| len.times { s << sample } }
  end

  def bump(char, delay)
    f, n = @bumps[@char_index[char]]
    @bumps[@char_index[char]] = {f + delay, n + 1}
  end
 
  def self.load : Generator
    @@generator ||= new
  end

  # The main function that returns a random number from @chars according to
  # distribution array defined by @freqs.
  private def sample : Char
    # Create and fill prefix array
    prefix = @freqs.dup
    prefix.each_index.each_cons(2) {|(prev, curr)| prefix[curr] += prefix[prev] }

    # prefix.last is sum of all frequencies. Generate a random number
    # with value from 1 to this sum
    r = rand(prefix.last) + 1

    # Find index of ceiling of r in the prefix array
    index = ceiling(prefix, r)
    @chars[index]
  end

  # Utility function to find ceiling of r in prefix[l..h]
  private def ceiling(prefix, r) : Int
    l, h = 0, prefix.size - 1
    while l < h
      mid = (l + h) / 2
      if r > prefix[mid] 
        l = mid + 1
      else
        h = mid
      end
    end
    prefix[l] >= r ? l : -1
  end
end