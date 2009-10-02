require 'test/unit'

%w(lib ../lib . ..).each{|d| $:.unshift d}
require 'slave' 

STDOUT.sync = true
STDERR.sync = true

class SlaveTest < Test::Unit::TestCase
#--{{{
  def setup
  end

  def teardown 
  end

  def test_00
    s = Slave.new Array.new
  end
#--}}}
end
