
class DummyText

  # Taken from http://www.lipsum.com/feed/html

  @@default_paragraph = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec odio mi, vestibulum ut sollicitudin id, adipiscing non sapien. Nunc lorem ante, consequat vitae viverra eu, dictum quis magna. Maecenas eget libero enim, commodo elementum arcu. Nulla facilisi. Donec porta, lectus vel gravida condimentum, massa lacus adipiscing sem, non ullamcorper risus ipsum ac magna. Maecenas vel arcu risus. Lorem ipsum dolor sit amet, consectetur adipiscing elit. In euismod odio in purus eleifend quis mollis tellus auctor. In porta tristique ante in hendrerit. Maecenas euismod, mi eu ornare aliquam, purus sapien hendrerit ante, vel ornare eros massa ut elit. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Pellentesque ut sagittis lectus. Duis sed metus a lorem porttitor accumsan.'
  def self.default_paragraph
    @@default_paragraph
  end

  def self.paragraph(amount=1, opts={})
    self.service.create_lipsum({:amount => amount, :what => 'paras', :start => 'no'}.merge(opts)) || self.default_paragraph
  end

  def self.paragraphs(num=5, opts={})
    min = opts[:min] || 1
    max = opts[:max] || 2
    start = 'yes'
    (1..num).collect do |p|
      lipsum = self.paragraph  min + rand(max-min+1), :start => start
      start = 'no'
      lipsum
    end
  end

  def self.words(amount=5, opts={})
    self.service.create_lipsum(:amount => amount, :what => 'words', :start => 'no') || 'Lorem ipsum dolor sit amet.'
  end

  def self.bytes(amount=30, opts={})
    self.service.create_lipsum(:amount => amount, :what => 'bytes', :start => 'no') || 'Lorem ipsum dolor sit amet.'
  end

  def self.lists(amount=1)
    lipsum = self.service.create_lipsum(:amount => amount, :what => 'lists', :start => 'no') || self.default_paragraph
    lipsum.split('. ').collect { |s| "#{s}." }
  end

  def self.service
    LoremIpsumWebService.new
  end

  class LoremIpsumWebService < ActiveWebService

    route :create_lipsum, '/feed/json', :expected_status => 200, :return => :handle_response

    def initialize
      self.base_uri = "http://www.lipsum.com"
    end

    def handle_response(response)
      response['feed']['lipsum'] if response && response['feed']
    end
  end
end
