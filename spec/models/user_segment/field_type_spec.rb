require File.dirname(__FILE__) + "/../../spec_helper"

describe UserSegment::FieldType do

  reset_domain_tables :tags

  it "should convert value to integer" do
    UserSegment::FieldType.convert_to("0", :integer).should == 0
    UserSegment::FieldType.convert_to(0, :integer).should == 0
    UserSegment::FieldType.convert_to("1", :integer).should == 1
    UserSegment::FieldType.convert_to(99, :integer).should == 99
    UserSegment::FieldType.convert_to(99.0, :integer).should be_nil
    UserSegment::FieldType.convert_to("99", :integer).should == 99
    UserSegment::FieldType.convert_to("1n", :integer).should be_nil
  end

  it "should convert value to float" do
    UserSegment::FieldType.convert_to("0", :float).should == 0.0
    UserSegment::FieldType.convert_to(0, :float).should == 0.0
    UserSegment::FieldType.convert_to("1", :float).should == 1.0
    UserSegment::FieldType.convert_to(99, :float).should == 99.0
    UserSegment::FieldType.convert_to(99.0, :float).should == 99.0
    UserSegment::FieldType.convert_to("99", :float).should == 99.0
    UserSegment::FieldType.convert_to("3.54", :float).should == 3.54
    UserSegment::FieldType.convert_to(3.54, :float).should == 3.54
    UserSegment::FieldType.convert_to("1n", :float).should be_nil
  end

  it "should only return string values" do
    UserSegment::FieldType.convert_to("hello world", :string).should == "hello world"
    UserSegment::FieldType.convert_to(1, :string).should be_nil
    UserSegment::FieldType.convert_to(true, :string).should be_nil
    UserSegment::FieldType.convert_to(false, :string).should be_nil
    UserSegment::FieldType.convert_to(nil, :string).should be_nil
    UserSegment::FieldType.convert_to(0.1, :string).should be_nil
    UserSegment::FieldType.convert_to(Time.now, :string).should be_nil
  end

  it "should convert value to time" do
    time = Time.parse "1/1/1990"
    UserSegment::FieldType.convert_to("1/1/1990", :datetime).should == time
    time = Time.now
    UserSegment::FieldType.convert_to(time, :datetime).should == time
  end

  it "should convert value to boolean" do
    UserSegment::FieldType.convert_to(true, :boolean).should == true
    UserSegment::FieldType.convert_to('true', :boolean).should == true
    UserSegment::FieldType.convert_to('TRUE', :boolean).should == true
    UserSegment::FieldType.convert_to(1, :boolean).should == true
    UserSegment::FieldType.convert_to('1', :boolean).should == true
    UserSegment::FieldType.convert_to(false, :boolean).should == false
    UserSegment::FieldType.convert_to('false', :boolean).should == false
    UserSegment::FieldType.convert_to('FALSE', :boolean).should == false
    UserSegment::FieldType.convert_to(0, :boolean).should == false
    UserSegment::FieldType.convert_to('0', :boolean).should == false
  end

  it "should convert value to option" do
    UserSegment::FieldType.convert_to('day', :option, :options => ['day', 'days', 'week', 'weeks']).should == 'day'
    UserSegment::FieldType.convert_to('Day', :option, :options => ['day', 'days', 'week', 'weeks']).should == 'day'
    UserSegment::FieldType.convert_to('DAY', :option, :options => ['day', 'days', 'week', 'weeks']).should == 'day'
    UserSegment::FieldType.convert_to('weeks', :option, :options => ['day', 'days', 'week', 'weeks']).should == 'weeks'
    UserSegment::FieldType.convert_to('WeeKs', :option, :options => ['day', 'days', 'week', 'weeks']).should == 'weeks'
    UserSegment::FieldType.convert_to('WeEk', :option, :options => ['day', 'days', 'week', 'weeks']).should == 'week'
    UserSegment::FieldType.convert_to('now', :option, :options => ['day', 'days', 'week', 'weeks']).should be_nil
    UserSegment::FieldType.convert_to('dayss', :option, :options => ['day', 'days', 'week', 'weeks']).should be_nil
  end

  it "should covert all the arguments" do
    arguments = ['1', 'test', 'true', '1/1/1990', 'Days', '1day']
    types = [:integer, :string, :boolean, :datetime, :option, :integer]
    options = [{}, {}, {}, {}, {:options => ['day', 'days', 'week', 'weeks']}]

    converted = UserSegment::FieldType.convert_arguments(arguments, types, options)
    converted[0].should == 1
    converted[1].should == 'test'
    converted[2].should == true
    converted[3].should == Time.parse('1/1/1990')
    converted[4].should == 'days'
    converted[5].should be_nil
  end

  it "should be able to register and operation" do
    UserSegment::FieldType.register_operation(:from, [['Value', :integer], ['Option', :option, {:options => ['day', 'days']}]])
    UserSegment::FieldType.has_operation?('from').should be_true
    operation = UserSegment::FieldType.user_segment_field_type_operations[:from]
    converted = UserSegment::FieldType.convert_arguments([1, 'Day'], operation[:arguments], operation[:argument_options])
    converted[0].should == 1
    converted[1].should == 'day'
  end

  it "should support model options" do
    bunnies = Tag.get_tag('bunnies')
    rabbits = Tag.get_tag('rabbits')
    poster = Tag.get_tag('poster')
    walker = Tag.get_tag('walker')

    UserSegment::FieldType.convert_to(bunnies.id.to_s, :model, :class => Tag).should == bunnies.id
    UserSegment::FieldType.convert_to(poster.id, :model, :class => Tag).should == poster.id
    UserSegment::FieldType.convert_to(98789, :model, :class => Tag).should be_nil
    UserSegment::FieldType.convert_to('Walker', :model, :class => Tag).should be_nil
  end
end
