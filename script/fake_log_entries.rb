#!/usr/bin/env ruby

require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'httparty'

DOMAIN_ID = 3

class MyRobotsWebService < ActiveWebService
  attr_accessor :authenticity_token
  attr_accessor :cookies
  attr_accessor :user
  attr_accessor :shop_resource

  @@fake_users = []
  CSV.open(ARGV[0], 'r') do |r|
    user = {:name => r[1], :address => r[2], :city => r[3], :state => r[4], :zip => r[5], :country => r[6], :email => r[7], :phone => r[8]}
    next if user[:country] == 'CAN'
    user[:first_name], user[:last_name] = user[:name].split(' ')
    user[:country] = user[:country] == 'CAN' ? 'Canada' : 'United States'
    @@fake_users << user
  end

  def self.get_random_user
    @@fake_users[rand(@@fake_users.size)]
  end

  def get_random_user
    @user ||= self.class.get_random_user
  end

  route :webalytics, '/webalytics'
  route :home, '/', :return => :handle_response
  route :about_us, '/about-us', :return => :handle_response
  route :faqs, '/faqs', :return => :handle_response
  route :contact, '/contact-us', :return => :handle_response
  route :add_contact, '/contact-us', :return => :handle_response, :resource => 'entry_1'
  route :shop, '/shop', :return => :handle_response
  route :cart, '/shop/cart', :return => :handle_response
  route :checkout, '/shop/checkout', :return => :handle_response
  route :register, '/shop/checkout', :method => :post, :return => :handle_response, :resource => 'register'
  route :shipping, '/shop/checkout/address', :method => :post, :return => :handle_response, :resource => 'shipping_address'
  route :payment, '/shop/checkout/payment', :method => :post, :return => :handle_response, :resource => 'payment'
  route :processing, '/shop/checkout/processing', :return => :handle_response
  route :success, '/shop/success', :return => :handle_response

  route :butler_bots, '/shop/butler-bots', :return => :handle_response

  route :belly_bot, '/shop/butler-bots/belly-bot', :return => :handle_response
  route :bubblegum_bot, '/shop/butler-bots/bubblegum-bot', :return => :handle_response
  route :peapod_alien_bot, '/shop/butler-bots/peapod-alien-bots', :return => :handle_response
  route :waving_walter, '/shop/butler-bots/waving-walter', :return => :handle_response

  route :add_belly_bot, '/shop/butler-bots/belly-bot', :return => :handle_response, :resource => 'shop'
  route :add_bubblegum_bot, '/shop/butler-bots/bubblegum-bot', :return => :handle_response, :resource => 'shop'
  route :add_peapod_alien_bot, '/shop/butler-bots/peapod-alien-bots', :return => :handle_response, :resource => 'shop'
  route :add_waving_walter, '/shop/butler-bots/waving-walter', :return => :handle_response, :resource => 'shop'

  route :robo_pets, '/shop/robo-pets', :return => :handle_response

  route :bird_bot, '/shop/robo-pets/bird-bot', :return => :handle_response
  route :froggy_bot, '/shop/robo-pets/froggy-bot', :return => :handle_response
  route :kitty_bot, '/shop/robo-pets/kitty-bot', :return => :handle_response
  route :neon_sheep_bot, '/shop/robo-pets/neon-sheep-bot', :return => :handle_response
  route :puppy_bot, '/shop/robo-pets/puppy-bot', :return => :handle_response

  route :add_bird_bot, '/shop/robo-pets/bird-bot', :return => :handle_response, :resource => 'shop'
  route :add_froggy_bot, '/shop/robo-pets/froggy-bot', :return => :handle_response, :resource => 'shop'
  route :add_kitty_bot, '/shop/robo-pets/kitty-bot', :return => :handle_response, :resource => 'shop'
  route :add_neon_sheep_bot, '/shop/robo-pets/neon-sheep-bot', :return => :handle_response, :resource => 'shop'
  route :add_puppy_bot, '/shop/robo-pets/puppy-bot', :return => :handle_response, :resource => 'shop'

  route :destructo_line, '/shop/destructo-line', :return => :handle_response

  route :black_bot, '/shop/destructo-line/black-bot', :return => :handle_response
  route :bombing_bot, '/shop/destructo-line/bombing-bot', :return => :handle_response
  route :map_manbot, '/shop/destructo-line/map-manbot', :return => :handle_response

  route :add_black_bot, '/shop/destructo-line/black-bot', :return => :handle_response, :resource => 'shop'
  route :add_bombing_bot, '/shop/destructo-line/bombing-bot', :return => :handle_response, :resource => 'shop'
  route :add_map_manbot, '/shop/destructo-line/map-manbot', :return => :handle_response, :resource => 'shop'

  route :vintage_bots, '/shop/vintage-bots', :return => :handle_response

  route :blue_bot, '/shop/vintage-bots/blue-bot', :return => :handle_response
  route :family_bots, '/shop/vintage-bots/family-bots', :return => :handle_response
  route :femm_bot, '/shop/vintage-bots/femm-bot', :return => :handle_response
  route :green_googles_bot, '/shop/vintage-bots/green-googles-bot', :return => :handle_response
  route :vintage_color_bot, '/shop/vintage-bots/vintage-color-bot', :return => :handle_response
  route :windup_gray_bot, '/shop/vintage-bots/windup-gray-bot', :return => :handle_response

  route :add_blue_bot, '/shop/vintage-bots/blue-bot', :return => :handle_response, :resource => 'shop'
  route :add_family_bots, '/shop/vintage-bots/family-bots', :return => :handle_response, :resource => 'shop'
  route :add_femm_bot, '/shop/vintage-bots/femm-bot', :return => :handle_response, :resource => 'shop'
  route :add_green_googles_bot, '/shop/vintage-bots/green-googles-bot', :return => :handle_response, :resource => 'shop'
  route :add_vintage_color_bot, '/shop/vintage-bots/vintage-color-bot', :return => :handle_response, :resource => 'shop'
  route :add_windup_gray_bot, '/shop/vintage-bots/windup-gray-bot', :return => :handle_response, :resource => 'shop'

  route :eyeclops, '/shop/eyeclops', :return => :handle_response

  route :eyeclops_bots, '/shop/eyeclops/eyeclops-bots', :return => :handle_response
  route :eyeclops_googly_bots, '/shop/eyeclops/googly-eyed-bots', :return => :handle_response

  route :add_eyeclops_bots, '/shop/eyeclops/eyeclops-bots', :return => :handle_response, :resource => 'shop'
  route :add_eyeclops_googly_bots, '/shop/eyeclops/googly-eyed-bots', :return => :handle_response, :resource => 'shop'

  route :vintage_bots_2, '/shop/vintage-bots-2', :return => :handle_response

  route :vintage_bots_2_bots, '/shop/vintage-bots-2/vintage-bots', :return => :handle_response

  route :add_vintage_bots_2_bots, '/shop/vintage-bots-2/vintage-bots', :return => :handle_response, :resource => 'shop'


  def initialize
    self.base_uri = "http://myrobots.com"
  end

  def save_cookies
    @cookies ||= {}
    @response.headers['set-cookie'].collect { |cookie| cookie.split("\; ")[0].split('=') }.each do |c|
      @cookies[c[0]] = c[1]
    end
  end

  def save_auth_token
    return unless @response.code == 200
    if @response.body =~ /['"]authenticity_token['"].*?value=['"](.*?)['"]/
      @authenticity_token = $1
    end

    if @response.body =~ /name='(shop\d+)/
      @shop_resource = $1
    end
  end

  def handle_response(response)
    save_cookies
    save_auth_token
    update_ip
  end

  def build_options!(options)
    super
    options[:headers] ||= {}
    options[:headers]['cookie'] = @cookies.to_a.collect{|c| "#{c[0]}=#{c[1]}"}.join('; ') + ';' if @cookies
    if options[:body]
      options[:body]['authenticity_token'] = @authenticity_token

      if options[:body]['shop'] && @shop_resource
        options[:body]['shop']['product'] = self.product_id @request_url
        options[:body][@shop_resource] = options[:body].delete('shop')
      end

      if options[:body]['register']
        options[:body]['commit'] = 'Continue'
      end

      if options[:body]['shipping_address']
        options[:body]['same_address'] = '1'
        options[:body]['billing_address'] = options[:body]['shipping_address']
      end

      if options[:body]['payment']
        options[:body]['commit'] = 'Submit Order'
      end
    end

    add_referer! options
    add_tracking! options
  end

  def add_referer!(options)
    return if @add_referer
    @add_referer = true
    @referers ||= [
      'http://www.google.com/#sclient=psy&hl=en&q=evil+genius+robots&aq=f&aqi=&aql=&oq=&gs_rfai=&pbx=1&fp=ab5cdb1806fef4aa',
      'http://search.yahoo.com/search;_ylt=A0WTfZ1Slo5MC28BpR2bvZx4?p=evil+robots&toggle=1&cop=mss&ei=UTF-8&fr=yfp-t-701',
      'http://www.google.com/#sclient=psy&hl=en&q=evil+genius+robots&aq=f&aqi=&aql=&oq=&gs_rfai=&pbx=1&fp=ab5cdb1806fef4aa',
      'http://search.yahoo.com/search;_ylt=A0WTfZ1Slo5MC28BpR2bvZx4?p=evil+robots&toggle=1&cop=mss&ei=UTF-8&fr=yfp-t-701',
      'http://www.google.com/#sclient=psy&hl=en&q=evil+robots&aq=f&aqi=&aql=&oq=&gs_rfai=&pbx=1&fp=ab5cdb1806fef4aa',
      'http://search.yahoo.com/search;_ylt=A0WTfZ1Slo5MC28BpR2bvZx4?p=robots&toggle=1&cop=mss&ei=UTF-8&fr=yfp-t-701',
      'http://www.robots.com/robots.php',
      'http://www.robots.com/',
      'http://myrobots.com/',
      'http://www.facebook.com/robots'
    ]

    if rand(100) < 10
      options[:headers]['referer'] = @referers[rand(@referers.size)]
    end
  end

  def add_tracking!(options)
    return if @add_tracking
    @add_tracking = true
    @affiliates ||= ['google', 'yahoo', 'msn']
    @campaigns ||= ['cms', 'trial', 'subscription']
    @origins ||= {'google' => ['cmsworld.com', 'feedburner.com']}

    if rand(100) < 30
      affid = @affiliates[rand(@affiliates.size)]
      c = @campaigns[rand(@campaigns.size)]
      o = @origins[affid] ? @origins[affid][rand(@origins[affid].size)] : ''
      f = 1 + rand(100000)
      options[:query] = "affid=#{affid}&c=#{c}&o=#{o}&f=#{f}"
    end
  end

  def add_product(product)
    self.send product
    self.send "add_#{product}", 'quantity' => 1+rand(3), 'action' => 'add_to_cart', 'product' => 1
  end

  def add_random_product
    self.add_product self.random_product
  end

  def purchase
    user = self.get_random_user
    self.checkout
    self.register 'first_name' => user[:first_name], 'last_name' => user[:last_name], 'email' => user[:email]
    self.shipping 'first_name' => user[:first_name], 'last_name' => user[:last_name], 'address' => user[:address], 'country' => user[:country], 'city' => user[:city], 'state' => user[:state], 'zip' => user[:zip]
    self.payment 'shipping_category' => 7, 'selected_processor_id' => 6, '6' => {'type' => 'standard', 'card_type' => 'visa', 'cc' => '1', 'cvc' => '111', 'exp_month' => '12', 'exp_year' => '2012'}
    self.processing
  end

  def contact_us
    user = self.get_random_user
    self.contact
    self.add_contact 'name' => user[:name], 'email' => user[:email], 'message' => DummyText.paragraph
  end

  def product_id(url)
    @product_urls ||= {
      'belly-bot' => 1, 
      'bird-bot' => 2, 
      'black-bot' => 3, 
      'blue-bot' => 4,
      'bombing-bot' => 5,
      'bubblegum-bot' => 6,
      'eyeclops-bot' => 7,
      'family-bots' => 8,
      'femm-bot' => 9,
      'froggy-bot' => 10,
      'googly-eyed-bots' => 11,
      'green-goggles-bot' => 12,
      'kitty-bot' => 13,
      'map-manbot' => 14,
      'neon-sheep-bot' => 15,
      'peapod-alien-bots' => 16,
      'puppy-bot' => 17,
      'vintage-bots' => 18,
      'vintage-color-bot' => 19,
      'waving-walter' => 20,
      'windup-gray-bot' => 21
    }

    if url =~ /shop\/.*?\/(.*)/
      @product_urls[$1]
    end
  end

  def random_product
    @products ||= [
      'belly_bot',
      'bubblegum_bot',
      'peapod_alien_bot',
      'waving_walter',
      'bird_bot',
      'froggy_bot',
      'kitty_bot',
      'neon_sheep_bot',
      'puppy_bot',
      'black_bot',
      'bombing_bot',
      'map_manbot',
      'blue_bot',
      'family_bots',
      'femm_bot',
      'green_googles_bot',
      'vintage_color_bot',
      'windup_gray_bot',
      'eyeclops_bots',
      'eyeclops_googly_bots',
      'vintage_bots_2_bots'
    ]
    @products[rand(@products.size)]
  end

  def random_ip
    @ip ||= "#{1+rand(255)}.#{1+rand(255)}.#{1+rand(255)}.#{1+rand(255)}"
  end

  def update_ip
    return if @update_ip
    @update_ip = true

    self.webalytics :query => {:loc => {:country => 'US'}}

    session = DomainLogSession.find_by_session_id @cookies['_session_id']
    session.update_attribute(:ip_address, self.random_ip) if session
    visitor = DomainLogVisitor.find_by_visitor_hash @cookies['v']
    visitor.update_attribute(:ip_address, self.random_ip) if visitor
  end
end

class ThreadCounter < Monitor
  attr_reader :count

  def initialize
    @count = 0
    super
  end

  def start
    synchronize do
      @count += 1
    end
  end

  def stop
    synchronize do
      @count -= 1
    end
  end
end

@counter = ThreadCounter.new
@domain = Domain.find DOMAIN_ID

def add_thread
  @counter.start
  Thread.new {
    @domain.execute {
      service = MyRobotsWebService.new

      percent = rand(100)
      if percent < 5
        puts "Buying robots"
        service.home
        service.shop
        (1+rand(5)).times do |t|
          service.add_random_product
        end
        service.purchase
      elsif percent < 15
        puts "Contacting Us"
        service.home
        service.contact_us
      elsif percent < 45
        puts "Bounce"
        service.home
      elsif percent < 50
        puts "Bounce"
        service.about_us
      else
        puts "Looking around"
        service.home
        service.about_us
        service.faqs
        service.shop
        (1+rand(20)).times do |t|
          service.send service.random_product
        end
      end
    }
    sleep 1 # + rand(10)
    @counter.stop
  }
end

max_threads = 6
max_threads.times do |i|
  add_thread
end

while(true)
  sleep 1
  puts "# threads: " + @counter.count.inspect
  if @counter.count < max_threads
    puts "starting a new thread"
    add_thread
  end
end
