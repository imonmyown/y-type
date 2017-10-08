require "yaml"

class Array(T)
  def normalize
    max = self.max
    self.map {|x| x.to_f / max }
  end

  def denormalize
    min = self.min
    self.map {|x| (x / min).to_i }
  end
end

class Generator
  getter chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890~`!@#$%^&*()_-+={}[]|\\;:\'\"<>,.?/"
  @config : String
  @@generator : Generator?

  def initialize
    # TODO: move to config
    dir = "#{ENV["HOME"]}/.y-type"
    Dir.mkdir(dir) unless Dir.exists?(dir)
    @config = dir + "/frequency.yaml"

    unless File.exists?(@config)
      @freqs = Array(Int32).new(@chars.size, 1)
      File.write(@config, @freqs.normalize)
    else
      @freqs = Array(Float32)
                  .from_yaml(File.read(@config))
                  .denormalize
    end
  end

  def finalize
    File.write(@config, @freqs.normalize)
  end

  def generate(len) : String
    String.build(len) {|s| len.times { s << sample } }
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