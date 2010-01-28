HERE = File.dirname(__FILE__)
$LOAD_PATH.unshift "#{HERE}/../lib"
#$LOAD_PATH << "/Library/Ruby/Gems/1.8/gems/activesupport-2.2.2/lib/active_support/vendor/memcache-client-1.5.1"

require 'benchmark'
require 'rubygems'
require 'test/unit'

$TESTING = true
require 'memcache' if not defined?(MemCache)

class TestBenchmark < Test::Unit::TestCase

  def setup
    puts "Testing #{MemCache::VERSION}"
    # We'll use a simple @value to try to avoid spending time in Marshal,
    # which is a constant penalty that both clients have to pay
    @value = []
    @marshalled = Marshal.dump(@value)
    
    @opts = [
      ['127.0.0.1:11211', 'localhost:11211'],
      {
        :namespace => "namespace",
#        :no_reply => true,
#        :timeout => nil,
      }
    ]
    @key1 = "Short"
    @key2 = "Sym1-2-3::45"*8
    @key3 = "Long"*40
    @key4 = "Medium"*8
    # 5 and 6 are only used for multiget miss test
    @key5 = "Medium2"*8 
    @key6 = "Long3"*40 
  end

  def test_benchmark
    Benchmark.bm(31) do |x|
    
      n = 2500
#      n = 1000
    
      @m = MemCache.new(*@opts)
      x.report("set:plain:memcache-client") do
        n.times do
          @m.set @key1, @marshalled, 0, true
          @m.set @key2, @marshalled, 0, true
          @m.set @key3, @marshalled, 0, true
          @m.set @key1, @marshalled, 0, true
          @m.set @key2, @marshalled, 0, true
          @m.set @key3, @marshalled, 0, true
        end
      end
    
      @m = MemCache.new(*@opts)
      x.report("set:ruby:memcache-client") do
        n.times do
          @m.set @key1, @value
          @m.set @key2, @value
          @m.set @key3, @value
          @m.set @key1, @value
          @m.set @key2, @value
          @m.set @key3, @value
        end
      end
    
      @m = MemCache.new(*@opts)
      x.report("get:plain:memcache-client") do
        n.times do
          @m.get @key1, true
          @m.get @key2, true
          @m.get @key3, true
          @m.get @key1, true
          @m.get @key2, true
          @m.get @key3, true
        end
      end
    
      @m = MemCache.new(*@opts)
      x.report("get:ruby:memcache-client") do
        n.times do
          @m.get @key1
          @m.get @key2
          @m.get @key3
          @m.get @key1
          @m.get @key2
          @m.get @key3
        end
      end

      @m = MemCache.new(*@opts)
      x.report("multiget:ruby:memcache-client") do
        n.times do
          # We don't use the keys array because splat is slow
          @m.get_multi @key1, @key2, @key3, @key4, @key5, @key6
        end
      end
    
      @m = MemCache.new(*@opts)
      x.report("missing:ruby:memcache-client") do
        n.times do
          begin @m.delete @key1; rescue; end
          begin @m.get @key1; rescue; end
          begin @m.delete @key2; rescue; end
          begin @m.get @key2; rescue; end
          begin @m.delete @key3; rescue; end
          begin @m.get @key3; rescue; end
        end
      end
          
      @m = MemCache.new(*@opts)
      x.report("mixed:ruby:memcache-client") do
        n.times do
          @m.set @key1, @value
          @m.set @key2, @value
          @m.set @key3, @value
          @m.get @key1
          @m.get @key2
          @m.get @key3
          @m.set @key1, @value
          @m.get @key1
          @m.set @key2, @value
          @m.get @key2
          @m.set @key3, @value
          @m.get @key3
        end
      end

      assert true
    end

  end
end