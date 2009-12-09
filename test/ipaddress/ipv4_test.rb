require 'test_helper'
 
class IPv4Test < Test::Unit::TestCase

  def setup
    @klass = IPAddress::IPv4

    @valid_ipv4 = {
      "10.0.0.0" => ["10.0.0.0", 8],
      "10.0.0.1" => ["10.0.0.1", 8],
      "10.0.0.1/24" => ["10.0.0.1", 24],
      "10.0.0.1/255.255.255.0" => ["10.0.0.1", 24]}
    
    @invalid_ipv4 = ["10.0.0.256",
                     "10.0.0.0.0",
                     "10.0.0",
                     "10.0"]

    @valid_ipv4_range = ["10.0.0.1-254",
                         "10.0.1-254.0",
                         "10.1-254.0.0"]

    @netmask_values = {
      "10.0.0.0/8"       => "255.0.0.0",
      "172.16.0.0/16"    => "255.255.0.0",
      "192.168.0.0/24"   => "255.255.255.0",
      "192.168.100.4/30" => "255.255.255.252"}

    @decimal_values ={      
      "10.0.0.0/8"       => 167772160,
      "172.16.0.0/16"    => 2886729728,
      "192.168.0.0/24"   => 3232235520,
      "192.168.100.4/30" => 3232261124}
    
    @ip = @klass.new("172.16.10.1/24")
    @network = @klass.new("172.16.10.0/24")
    
    @broadcast = {
      "10.0.0.0/8"       => "10.255.255.255",
      "172.16.0.0/16"    => "172.16.255.255",
      "192.168.0.0/24"   => "192.168.0.255",
      "192.168.100.4/30" => "192.168.100.7"}
    
    @networks = {
      "10.5.4.3/8"       => "10.0.0.0",
      "172.16.5.4/16"    => "172.16.0.0",
      "192.168.4.3/24"   => "192.168.4.0",
      "192.168.100.5/30" => "192.168.100.4"}
  end

  def test_initialize
    @valid_ipv4.keys.each do |i|
      ip = @klass.new(i)
      assert_instance_of @klass, ip
    end
  end

  def test_initialize_format_error
    @invalid_ipv4.each do |i|
      assert_raise(ArgumentError) {@klass.new(i)}
    end
  end

  def test_attributes
    @valid_ipv4.each do |arg,attr|
      ip = @klass.new(arg)
      assert_equal attr.first, ip.address
      assert_equal attr.last, ip.prefix.to_i
    end
  end

  def test_octets
    ip = @klass.new("10.1.2.3/8")
    assert_equal ip.octets, [10,1,2,3]
  end
  
  def test_initialize_should_require_ip
    assert_raise(ArgumentError) { @klass.new }
  end
  
  def test_method_to_s
    @valid_ipv4.each do |arg,attr|
      ip = @klass.new(arg)
      assert_equal attr.join("/"), ip.to_s
    end
  end
  
  def test_netmask
    @netmask_values.each do |addr,mask|
      ip = @klass.new(addr)
      assert_equal mask, ip.netmask
    end
  end

  def test_method_to_u32
    @decimal_values.each do |addr,int|
      ip = @klass.new(addr)
      assert_equal int, ip.to_u32
    end
  end

  def test_method_network?
    assert_equal true, @network.network?
    assert_equal false, @ip.network?
  end

  def test_method_broadcast
    @broadcast.each do |addr,bcast|
      ip = @klass.new(addr)
      assert_equal bcast, ip.broadcast
    end
  end
  
  def test_method_network
    @networks.each do |addr,net|
      ip = @klass.new addr
      assert_equal net, ip.network
    end
  end

  def test_method_bits
    ip = @klass.new("127.0.0.1")
    assert_equal ip.bits, "01111111000000000000000000000001"
  end

  def test_method_first
    ip = @klass.new("192.168.100.0/24")
    assert_equal "192.168.100.1", ip.first
    ip = @klass.new("192.168.100.50/24")
    assert_equal "192.168.100.1", ip.first
  end

  def test_method_last
    ip = @klass.new("192.168.100.0/24")
    assert_equal  "192.168.100.254", ip.last
    ip = @klass.new("192.168.100.50/24")
    assert_equal  "192.168.100.254", ip.last
  end
  
  def test_method_each_host
    ip = @klass.new("10.0.0.1/29")
    arr = []
    ip.each_host {|i| arr << i}
    expected = ["10.0.0.1","10.0.0.2","10.0.0.3","10.0.0.4","10.0.0.5","10.0.0.6"]
    assert_equal expected, arr
  end

  def test_method_each
    ip = @klass.new("10.0.0.1/29")
    arr = []
    ip.each {|i| arr << i}
    expected = ["10.0.0.0","10.0.0.1","10.0.0.2","10.0.0.3","10.0.0.4","10.0.0.5","10.0.0.6","10.0.0.7"]
    assert_equal expected, arr
  end

  def test_method_size
    ip = @klass.new("10.0.0.1/29")
    assert_equal 8, ip.size
  end

  def test_method_hosts
    ip = @klass.new("10.0.0.1/29")
    expected = ["10.0.0.1","10.0.0.2","10.0.0.3","10.0.0.4","10.0.0.5","10.0.0.6"]
    assert_equal expected, ip.hosts
  end

  def test_method_network_u32
    assert_equal 2886732288, @ip.network_u32
  end
  
  def test_method_broadcast_u32
    assert_equal 2886732543, @ip.broadcast_u32
  end

  def test_method_include?
    ip = @klass.new("192.168.10.100/24")
    addr = @klass.new("192.168.10.102/24")
    assert_equal true, ip.include?(addr)
    assert_equal false, ip.include?("172.16.0.48")
  end

  def test_method_octet
    assert_equal 172, @ip[0]
    assert_equal 16, @ip[1]
    assert_equal 10, @ip[2]
    assert_equal 1, @ip[3]
  end

  def test_method_reverse
    assert_equal "1.10.16.172.in-addr.arpa", @ip.reverse
  end
  
  def test_method_comparabble
    ip1 = @klass.new("10.1.1.1/8")
    ip2 = @klass.new("10.1.1.1/16")
    ip3 = @klass.new("172.16.1.1/14")
    ip4 = @klass.new("10.1.1.1/8")
    
    # ip1 should be major than ip2
    assert_equal true, ip1 > ip2
    assert_equal false, ip1 < ip2    
    # ip2 should be minor than ip3
    assert_equal true, ip2 < ip3
    assert_equal false, ip2 > ip3
    # ip1 should be minor than ip3
    assert_equal true, ip1 < ip3
    assert_equal false, ip1 > ip3
    # ip1 should be equal to itself
    assert_equal true, ip1 == ip1
    # ip1 should be equal to ip4
    assert_equal true, ip1 == ip4
    # test sorting
    arr = ["10.1.1.1/16","10.1.1.1/8","172.16.1.1/14"]
    assert_equal arr, [ip1,ip2,ip3].sort.map{|s| s.to_s}
  end

  
  def test_method_netmask_equal
    ip = @klass.new("10.1.1.1/16")
    assert_equal 16, ip.prefix.to_i
    ip.netmask = "255.255.255.0"
    assert_equal 24, ip.prefix.to_i
  end

   def test_method_subnet
     assert_raise (ArgumentError) {@ip.subnet(0)}
     assert_raise (ArgumentError) {@ip.subnet(257)}

     arr = ["172.16.10.0/26", "172.16.10.64/26", "172.16.10.128/26", "172.16.10.192/26"]
     assert_equal arr, @network.subnet(4).map {|s| s.to_s}
     #     assert_equal ip.subnet(3), ["172.16.10.0/26",
#                                 "172.16.10.64/26",
#                                 "172.16.10.128/25"]
   end

   def test_method_supernet
     assert_equal "172.16.8.0/23", @ip.supernet(23)
   end

  def test_classmethod_parse_u32
    @decimal_values.each do  |addr,int|
      ip = @klass.parse_u32(int)
      ip.prefix = addr.split("/").last.to_i
      assert_equal ip.to_s, addr
    end
  end

  def test_classmethod_summarize
    ip1 = @klass.new("172.16.10.1/24")
    ip2 = @klass.new("172.16.11.2/24")
#    assert_equal "172.16.10.1/23", @klass.summarize(ip1,ip2).to_s
  end

  
  
end # class IPv4Test

  