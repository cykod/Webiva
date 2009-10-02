require File.dirname(__FILE__) + '/../../test_helper'

class RemoteOrbitalPaymentechTest < Test::Unit::TestCase
  def setup
    fixture = fixtures(:orbital_paymentech).merge({:test => true})
    @certifying = fixture.delete(:certifying)
    @card_types = fixture.delete(:card_types).collect{|t| t.to_sym}
    @gateway = OrbitalPaymentechGateway.new(fixture)
    @options = {}

    if fixture[:routing_id] == SalemTest::ROUTING_ID
      class << self; include SalemTest; end
    elsif fixture[:routing_id] == TampaTest::ROUTING_ID
      class << self; include TampaTest; end
    else
      fail "Unrecognized routing ID: #{fixture[:routing_id]}"
    end
  end

  def test_authorize
    if @certifying
      with_cert_data {|amt, cc, opts| @gateway.authorize(amt, cc, opts)}
    else
      with_test_data do |amt, cc, opts, tests|
        tests.call(@gateway.authorize(amt, cc, opts))
      end
    end
  end

  def test_purchase
    if @certifying
      with_cert_data {|amt, cc, opts| @gateway.purchase(amt, cc, opts)}
    else
      with_test_data do |amt, cc, opts, tests|
        tests.call(@gateway.purchase(amt, cc, opts))
      end    
    end
  end

  def test_auth_mark_capture
    if @certifying
      with_cert_data(:mark_capture) do |amt, cc, opts| 
        auth = @gateway.authorize(amt, cc, opts)
        if auth.success?
          @gateway.capture(amt, auth.authorization, opts)
        else
          auth
        end
      end
    else
      with_test_data do |amt, cc, opts, tests|
        auth = @gateway.authorize(amt, cc, opts)
        tests.call(auth)
        if auth.success?
          assert capture = @gateway.capture(amt, auth.authorization, opts)
          assert_success capture
        end
      end    
    end
  end

  def test_void
    if @certifying
      with_cert_data(:void) do |amt, cc, opts| 
        purchase = @gateway.purchase(amt, cc, opts)
        if purchase.success?
          @gateway.void(purchase.params['transaction_id'], opts.merge({:transaction_ref_index => purchase.params['transaction_ref_index']}))
        else
          purchase
        end
      end
    else
      with_test_data do |amt, cc, opts, tests|
        purchase = @gateway.purchase(amt, cc, opts) 
        tests.call(purchase)
        if purchase.success?
          void = @gateway.void(purchase.params['transaction_id'], opts.merge({:transaction_ref_index => purchase.params['transaction_ref_index']}))
          assert_success void 
        end
      end    
    end
  end

  def test_invalid_login
    unless @certifying
      @options[:order_id] = 'FAIL000001'
      gateway = OrbitalPaymentechGateway.new(fixtures(:orbital_paymentech).update({
        :login => '',
        :password => ''
      }))

      assert response = gateway.purchase(10000, credit_card('4242424242424242'), @options)
      assert_failure response 
    end
  end

  module SalemTest
    ROUTING_ID = '000001'
    PASS_AMT = 10000
    PASS_CVV = '111'
    PASS_ZIP = '11111'

    TEST_CARDS = {
      :visa => {
        :number => '4444444444444448',
        :cvvs => {'11' => 'I',  '1111' => 'I',  '111' => 'M', '411' => 'N',  '412' => 'P',  '413' => 'U'}
      },
      :master => {
        :number => '5454545454545454',
        :cvvs => {'11' => 'I',  '1111' => 'I',  '111' => 'M', '511' => 'N',  '512' => 'P',  '513' => 'U'}
      },
      :discover => {
        :number => '6011000995500000',
        :cvvs => {'11' => 'I',  '1111' => 'I',  '111' => 'M', '611' => 'N',  '612' => 'P',  '613' => 'U'}
      },
      :american_express => {
        :number => '371449635398431', 
        :cvvs => {'1111' => nil, '111' => nil}
      },
      :jcb                           => {:number => '3566002020140006'},
      :visa_purchasing_card_iii      => {:number => '4055011111111111'},
      :mastercard_purchasing_card_ii => {:number => '5405222222222226'},
      :diners                        => {:number => '36438999960016'}
    }
   
    TEST_AMOUNTS = [
      { :amount => 10000,   :responses => {:visa => '00', :master => '00', :american_express => '00', :discover => '00'}},
      { :amount => 20100,   :responses => {:visa => '68', :master => '68', :american_express => '68', :discover => '68'}},
      { :amount => 20400,   :responses => {:visa => '66', :master => '66', :american_express => '66', :discover => '66'}},
      { :amount => 24900,   :responses => {:visa => 'BR', :master => 'BR', :american_express => 'BR', :discover => 'BR'}},
      { :amount => 25300,   :responses => {:visa => 'B1', :master => 'B1', :american_express => 'B1', :discover => 'B1'}},
      { :amount => 30100,   :responses => {:visa => '98', :master => '98', :american_express => '98', :discover => '98'}},
      { :amount => 30200,   :responses => {:visa => '89', :master => '89', :american_express => '89', :discover => '89'}},
      { :amount => 30300,   :responses => {:visa => '52', :master => '52', :american_express => '52', :discover => '00'}},
      { :amount => 30400,   :responses => {:visa => 'B5', :master => 'B5', :american_express => 'B5', :discover => '00'}},
      { :amount => 40100,   :responses => {:visa => '01', :master => '01', :american_express => '01', :discover => '01'}},
      { :amount => 40200,   :responses => {:visa => '10', :master => '10', :american_express => '10', :discover => '00'}},
      { :amount => 50100,   :responses => {:visa => '04', :master => '04', :american_express => '04', :discover => '04'}},
      { :amount => 50200,   :responses => {:visa => '41', :master => '41', :american_express => '00', :discover => '41'}},
      { :amount => 50300,   :responses => {:visa => '00', :master => '00', :american_express => '00', :discover => 'B7'}},
      { :amount => 50700,   :responses => {:visa => '00', :master => '00', :american_express => '00', :discover => '00'}},
      { :amount => 52200,   :responses => {:visa => '33', :master => '33', :american_express => '33', :discover => '33'}},
      { :amount => 53000,   :responses => {:visa => '05', :master => '05', :american_express => '05', :discover => '05'}},
      { :amount => 53100,   :responses => {:visa => '64', :master => '64', :american_express => '00', :discover => '00'}},
      { :amount => 59100,   :responses => {:visa => '14', :master => '14', :american_express => '14', :discover => '14'}},
      { :amount => 59200,   :responses => {:visa => '13', :master => '13', :american_express => '13', :discover => '13'}},
      { :amount => 59400,   :responses => {:visa => '06', :master => '06', :american_express => '06', :discover => '06'}},
      { :amount => 59500,   :responses => {:visa => 'BS', :master => 'BS', :american_express => 'BS', :discover => 'BS'}},
      { :amount => 59600,   :responses => {:visa => 'BQ', :master => 'BQ', :american_express => 'BQ', :discover => 'BQ'}},
      { :amount => 60200,   :responses => {:visa => '72', :master => '72', :american_express => '72', :discover => '00'}},
      { :amount => 60300,   :responses => {:visa => 'E4', :master => 'E4', :american_express => 'E4', :discover => '00'}},
      { :amount => 60500,   :responses => {:visa => '74', :master => '74', :american_express => '74', :discover => '00'}},
      { :amount => 60600,   :responses => {:visa => '12', :master => '12', :american_express => '00', :discover => '12'}},
      { :amount => 60700,   :responses => {:visa => '77', :master => '77', :american_express => '77', :discover => '77'}},
#- F3?      { :amount => 75400,   :responses => {:visa => 'BK', :master => 'BK', :american_express => 'BK', :discover => 'BK'}},
      { :amount => 80200,   :responses => {:visa => '50', :master => '50', :american_express => '50', :discover => '00'}},
      { :amount => 80600,   :responses => {:visa => '56', :master => '56', :american_express => '56', :discover => '56'}},
      { :amount => 81100,   :responses => {:visa => '00', :master => '00', :american_express => '65', :discover => '00'}},
      { :amount => 81300,   :responses => {:visa => 'H9', :master => 'H9', :american_express => 'H9', :discover => '00'}},
      { :amount => 82500,   :responses => {:visa => '71', :master => '71', :american_express => '00', :discover => '00'}},
      { :amount => 83300,   :responses => {:visa => '79', :master => '79', :american_express => '79', :discover => '79'}},
      { :amount => 90200,   :responses => {:visa => 'L2', :master => 'L2', :american_express => 'L2', :discover => '00'}},
      { :amount => 90300,   :responses => {:visa => 'L3', :master => 'L3', :american_express => 'L3', :discover => 'L3'}},
      { :amount => 90400,   :responses => {:visa => 'L4', :master => 'L4', :american_express => 'L4', :discover => '00'}},
      { :amount => 99900,   :responses => {:visa => '99', :master => '99', :american_express => '99', :discover => '99'}}
    ]
    
    class AVSTest
      attr_reader :zip, :cases

      def initialize(zip, &block)
        @zip = zip
        @cases = []
        instance_eval &block
      end

      def add_case(zip4_present, addr_present, responses = {})
        @cases << Case.new(self, zip4_present, addr_present, responses)
      end

      class Case
        def initialize(avstest, zip4_present, addr_present, responses = {})
          @avstest = avstest
          @zip4_present = zip4_present
          @addr_present = addr_present
          @responses = responses
        end

        def evaluate(base, cardtype, response, fail_message)
          expected = @responses[cardtype] || @responses[:default]
          base.assert_equal expected, response, fail_message
        end

        def address
          address = { :zip => @avstest.zip + (@zip4_present ? '-0001' : '') }
          if @addr_present
            address.merge({
              :address1 => '2866 Small Street',
              :city => 'New York',
              :state => 'NY',
              :country => 'US'
            })
          end
          address
        end
      end
    end
    
    AVS_TESTS = [
      AVSTest.new('11111') { add_case(false, false, {:default => 'C', :visa => 'C'})
                             add_case(true,  true,  {:default => '9', :visa => 'B'})
                             add_case(true,  false, {:default => 'A', :visa => 'C'})
                             add_case(false, true,  {:default => 'B', :visa => 'B'}) },
      AVSTest.new('03101') { add_case(false, false, {:default => 'C', :visa => 'C'})
                             add_case(false, true,  {:default => 'B', :visa => 'B'})
                             add_case(true,  false, {:default => 'A', :visa => 'C'})
                             add_case(true,  true,  {:default => '9', :visa => 'B'}) },
      AVSTest.new('03102') { add_case(true,  nil,   {:default => 'A', :visa => 'C'})
                             add_case(false, nil,   {:default => 'C', :visa => 'C'}) },
      AVSTest.new('03103') { add_case(nil,   true,  {:default => 'B', :visa => 'B'})
                             add_case(nil,   false, {:default => 'C', :visa => 'C'}) },
      AVSTest.new('03104') { add_case(nil,   nil,   {:default => 'C', :visa => 'C'}) },
      AVSTest.new('03105') { add_case(true,  true,  {:default => 'D', :visa => 'F'})
                             add_case(false, true,  {:default => 'F', :visa => 'F'})
                             add_case(true,  false, {:default => 'E', :visa => 'G'})
                             add_case(false, false, {:default => 'G', :visa => 'G'}) },
      AVSTest.new('03106') { add_case(true,  nil,   {:default => 'E', :visa => 'G'})
                             add_case(false, nil,   {:default => 'G', :visa => 'G'}) },
      AVSTest.new('03107') { add_case(nil,   true,  {:default => 'F', :visa => 'F'})
                             add_case(nil,   false, {:default => 'G', :visa => 'G'}) },
      AVSTest.new('03108') { add_case(nil,   nil,   {:default => 'G', :visa => 'G'}) },
      AVSTest.new('03109') { add_case(true,  true,  {:default => '9', :visa => 'JB'})
                             add_case(true,  false, {:default => 'A', :visa => 'JB'})
                             add_case(false, true,  {:default => 'B', :visa => 'JB'})
                             add_case(false, false, {:default => 'C', :visa => 'JB'}) },
      AVSTest.new('03110') { add_case(true,  true,  {:default => '9', :visa => 'JC'})
                             add_case(true,  false, {:default => 'A', :visa => 'JC'})
                             add_case(false, true,  {:default => 'B', :visa => 'JC'})
                             add_case(false, false, {:default => 'C', :visa => 'JC'}) },
      AVSTest.new('03111') { add_case(nil,   nil,   {:default => 'R', :visa => 'R'}) },
      AVSTest.new('03060') { add_case(nil,   nil,   {:default => '5', :visa => '5'}) },
      AVSTest.new('03061') { add_case(true,  true,  {:default => '9', :visa => 'JD'})
                             add_case(true,  false, {:default => 'A', :visa => 'JD'})
                             add_case(false, true,  {:default => 'B', :visa => 'JD'})
                             add_case(false, false, {:default => 'C', :visa => 'JD'}) },
      AVSTest.new('03062') { add_case(nil,   nil,   {:default => '6', :visa => '6'}) },
      AVSTest.new('03063') { add_case(nil,   nil,   {:default => '7', :visa => '7'}) }
    ]
     
    def test_cards
      TEST_CARDS.reject{|k,v| !@card_types.include?(k)}
    end

    def with_test_data(&block)
      order_count = 0
      order_count = with_response_tests(order_count, &block)
      order_count = with_avs_tests(order_count, &block)
      order_count = with_cvv_tests(order_count, &block)
    end

    def with_response_tests(order_count, &block)
      avstest = AVS_TESTS[0]
      avscase = avstest.cases[0]
      @options[:address] = avscase.address

      TEST_AMOUNTS.each do |amtdata|
        test_cards.each do |cardtype, ccdata|
          order_count += 1
          @options[:order_id] = "TEST#{sprintf("%06d", order_count)}"

          creditcard = credit_card(ccdata[:number]) 
          creditcard.verification_value = PASS_CVV

          tests = lambda do |response|
            fail_message = 
              "failed on data: cc = #{ccdata[:number]} : #{PASS_CVV}; amount = #{amtdata[:amount]}; zip = #{avstest.zip}; " <<
              "options: #{@options.inspect};"

            amtdata[:responses][cardtype] == '00' ? assert_success(response, fail_message) : assert_failure(response, fail_message)
            assert_equal amtdata[:responses][cardtype], response.params['response_code'], "response: #{response.inspect} " << fail_message
          end

          block.call(amtdata[:amount], creditcard, @options, tests)
        end
      end

      order_count
    end

    def with_cvv_tests(order_count, &block)
      amtdata = TEST_AMOUNTS[0]
      avstest = AVS_TESTS[0]
      avscase = avstest.cases[0]
      @options[:address] = avscase.address

      test_cards.each do |cardtype, ccdata|
        ccdata[:cvvs].each do |cvv, cvv_expected|
          order_count += 1
          @options[:order_id] = "TEST#{sprintf("%06d", order_count)}"

          creditcard = credit_card(ccdata[:number]) 
          creditcard.verification_value = cvv

          tests = lambda do |response|
            fail_message = 
              "failed on data: cc = #{ccdata[:number]} : #{cvv}; amount = #{amtdata[:amount]}; zip = #{avstest.zip}; " <<
              "options: #{@options.inspect};"

            assert_equal cvv_expected, response.cvv_result['code'], "response: #{response.inspect} " << fail_message
          end

          block.call(amtdata[:amount], creditcard, @options, tests)
        end
      end

      order_count
    end

    def with_avs_tests(order_count, &block)
      amtdata = TEST_AMOUNTS[0]
      test_cards.each do |cardtype, ccdata|
        creditcard = credit_card(ccdata[:number]) 
        creditcard.verification_value = PASS_CVV

        AVS_TESTS.each do |avstest|
          avstest.cases.each do |avscase|
            order_count += 1
            @options[:order_id] = "TEST#{sprintf("%06d", order_count)}"

            @options[:address] = avscase.address

            tests = lambda do |response|
              fail_message = 
                "failed on data: cc = #{ccdata[:number]} : #{PASS_CVV}; amount = #{amtdata[:amount]}; zip = #{avstest.zip}; " <<
                "options: #{@options.inspect};"
                            
              avscase.evaluate self, cardtype, response.avs_result['code'], "response: #{response.inspect} " << fail_message
            end

            block.call(amtdata[:amount], creditcard, @options, tests)
          end
        end
      end

      order_count
    end  

    def with_cert_data(operation = nil, &block)
      order_index = 0
      print_cert_response_header 
      test_cards.each do |cardtype, ccdata|
        order_index += 1
        @options[:order_id] = "CERT#{sprintf("%06d", order_index)}"
        @options[:address] = {:zip => '11111'}

        creditcard = credit_card(ccdata[:number], :verification_value => '111') 

        response = block.call(10000, creditcard, @options, response)
        print_cert_response(10000, creditcard, @options, response)
      end
    end
  end

  module TampaTest
    ROUTING_ID = '000002'

    AUTH_TEST_AMOUNTS = [
      {:amount => 100, :code => '00'},
      {:amount => 101, :code => '05'},
      {:amount => 102, :code => '01'},
      {:amount => 103, :code => '04'},
      {:amount => 104, :code => '19'},
      {:amount => 105, :code => '14'},
      {:amount => 106, :code => '74'},
      {:amount => 107, :code => 'L5'},
      {:amount => 110, :code => '03'},
      {:amount => 112, :code => '13'},
      {:amount => 113, :code => '12'},
      {:amount => 116, :code => '43'},
      {:amount => 121, :code => '06'}
    ]
    
    AVS_TEST_ZIPCODES = [
      {:zip => '11111', :code => 'F'},
      {:zip => '33333', :code => 'G'},
      {:zip => '44444', :code => '6'},
      {:zip => '55555', :code => '7'},
      {:zip => '66666', :code => 'H'},
      {:zip => '77777', :code => 'X'},
      {:zip => '77777', :code => 'Z'},
      {:zip => '88888', :code => '4'}
    ]
    
    CVV_TEST_CODES = [
      {:cvv => '111', :code => 'M'}, 
      {:cvv => '222', :code => 'N'}, 
      {:cvv => '333', :code => 'P'}, 
      {:cvv => '444', :code => 'S'}, 
      {:cvv => '555', :code => 'U'}, 
      {:cvv => '666', :code => ' '} 
    ]
    
    TEST_CARDS = {
      :visa                          => '4012888888881',
      :master                        => '5454545454545454',
      :american_express              => '371449635398431',
      :discover                      => '6011601160116611',
      :jcb                           => '3566002020140006',
      :visa_purchasing_card_ii       => '4055011111111111',
      :mastercard_purchasing_card_ii => '5405222222222226',
      :diners                        => '36438999960016'
    }
    
    def test_cards
      TEST_CARDS.reject{|k,v| @card_types[k].nil?}
    end

    def with_test_data(&block)
      order_index = 0
      @options[:address] = {}
      AUTH_TEST_AMOUNTS.each do |amtdata|
        AVS_TEST_ZIPCODES.each do |avsdata|
          CVV_TEST_CODES.each do |cvvdata|
            test_cards.each do |cardtype, number|
              order_index += 1
              @options[:order_id] = "TEST#{sprintf("%06d", order_index)}"

              @options[:address][:zip] = avsdata[:zip]
              creditcard = credit_card(number, :verification_value => cvvdata[:cvv])
              valid = amtdata[:valid] && avsdata[:valid] && cvvdata[:valid]
              fail_message = 
                "failed on data: cc = #{number} : #{cvvdata[:cvv]}; amount = #{amtdata[:amount]}; zip = #{avsdata[:zip]}; " <<
                "options: #{@options.inspect}; "

              tests = lambda do |response|
                valid ? assert_success(response, fail_message) : assert_failure(response, fail_message)
                assert_equal amtdata[:code], response.params['response_code'], "response: #{response.inspect} " << fail_message
                assert_equal cvvdata[:code], response.cvv_result['code'], "response: #{response.inspect} " << fail_message
                assert_equal avsdata[:code], response.avs_result['code'], "response: #{response.inspect} " << fail_message
              end

              block.call(amtdata[:amount], creditcard, @options, tests)
            end
          end
        end
      end    
    end  

    def with_cert_data(operation = nil, &block)
      tests = [
        [ 3000,   :visa,              '111',  {:order_id => 'CERT000001', :address => address(:zip => '11111')} ],
        [ 3801,   :visa,              '222',  {:order_id => 'CERT000002', :address => address(:zip => '33333')} ],
        [ 4100,   :master,            '333',  {:order_id => 'CERT000003', :address => address(:zip => '44444')} ],
        [ 1102,   :master,            '666',  {:order_id => 'CERT000004', :address => address(:zip => '88888')} ],
        [ 105500, :american_express,  '1111', {:order_id => 'CERT000005', :address => address(:zip => '55555')} ],
        [ 7500,   :american_express,  '555',  {:order_id => 'CERT000006', :address => address(:zip => '66666')} ],
        [ 1000,   :discover,          '666',  {:order_id => 'CERT000007', :address => address(:zip => '77777')} ],
        [ 6303,   :discover,          '444',  {:order_id => 'CERT000008', :address => address(:zip => '88888')} ],
        [ 2900,   :jcb,               nil,    {:order_id => 'CERT000009', :address => address(:zip => '33333')} ]
      ]

      orders = case operation
      when :mark_capture
        [1,3,5,7,9]
      when :void
        [1,5,9]
      else
        1..9 
      end

      print_cert_response_header 
      orders.each do |i|
        amount, cardtype, cvv, opts = tests[i-1]
        if @card_types.include?(cardtype)
          card = credit_card(test_cards[cardtype], :verification_value => cvv)
          response = block.call(amount, card, opts)
          print_cert_response(amount, card, opts, response)
        end
      end
    end
  end

  private

  def print_cert_response_header
    puts %w( Order# Amount CC# CCV Zipcode respDateTime TxRefNum RespCode AVS CVD ).join("\t")
  end

  def print_cert_response(amount, creditcard, options, response)
    puts [
      response.params['order_id'],
      amount,
      creditcard.number,
      creditcard.verification_value,
      options[:address][:zip],
      response.params['transaction_date'],
      response.params['transaction_id'],
      response.params['response_code'],
      response.avs_result['code'],
      response.cvv_result['code']
    ].join("\t")
  end
end
