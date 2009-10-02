require 'rubygems'
require 'yaml'
require_gem 'activerecord'

config = open("config.yml") { |f| YAML.load(f.read)}

ActiveRecord::Base.establish_connection(config["database"])


#AR_PATH = Gem::GemPathSearcher.new.find("active_record").full_gem_path
#$:.unshift("#{AR_PATH}/test")
#$:.unshift("#{AR_PATH}/test/connections/native_mysql")
$:.unshift(File.dirname(__FILE__) + '/../lib')

#require 'abstract_unit'
require 'taggable'

@@tag_table_column_name = :name

ActiveRecord::Base.connection.drop_table :tags rescue nil
ActiveRecord::Base.connection.drop_table :tags_topics rescue nil
ActiveRecord::Base.connection.drop_table :topics rescue nil
ActiveRecord::Base.connection.drop_table :people rescue nil
ActiveRecord::Base.connection.drop_table :tag_people rescue nil



ActiveRecord::Base.connection.create_table :topics do |t|
    t.column :name, :string
end

ActiveRecord::Base.connection.create_table :tags do |t|
    t.column @@tag_table_column_name , :string
end

ActiveRecord::Base.connection.create_table :tags_topics, :id => false do |t|
    t.column :tag_id, :integer
    t.column :topic_id, :integer
end

ActiveRecord::Base.connection.create_table :people do |t|
    t.column :name, :string
    t.column :email , :string
end
ActiveRecord::Base.connection.create_table :tag_people do |t|
    t.column :tag_id, :integer
    t.column :person_id, :integer
    t.column :created_at, :datetime
    t.column :created_by_id, :integer
    t.column :position, :integer
end

class Tag < ActiveRecord::Base
end
class Topic < ActiveRecord::Base
  acts_as_taggable
end

class TagPerson < ActiveRecord::Base
    acts_as_list :scope => :person
    belongs_to :created_by, :class_name => "Person", :foreign_key => 'created_by_id'
end

class Person < ActiveRecord::Base
    acts_as_taggable :join_class_name => 'TagPerson'
end



class ActAsTaggableTest < Test::Unit::TestCase

#singleton commands = [:replace_tag,  :find_related_tagged, :cloud ]
#class_commands =  tag_names=, tagged_related,tags
    def setup
        Tag.delete_all
        Topic.delete_all
        Person.delete_all
        TagPerson.delete_all
        @topic= Topic.new(:name => "Plugin")
        @topic.save
        @first_person = Person.new(:name => "Mike User", :email => "mike@aol.com")
        @first_person.save
        @second_person = Person.new(:name => "Sally User", :email => "sally@aol.com")
        @second_person.save
    end
    def test_simple_find_tagged_with
        @topic.tag "Rails Ruby"
        assert_equal [@topic], Topic.find_tagged_with(:any => "Rails")
        assert_equal [@topic], Topic.find_tagged_with(:all => "Rails Ruby")
    end
    def test_join_find_tagged_with
        @first_person.tag "Employee Manager"
        assert_equal [@first_person], Person.find_tagged_with(:any => "Employee")
        assert_equal [@first_person], Person.find_tagged_with(:all => "Employee Manager")
    end
    def test_simple_find_related_tags
        @topic.tag "foo'bar,baz", :separator => "," , :clear =>true
        result = { "baz" => 1}
        assert_equal result,Topic.find_related_tags("foo'bar")
        assert_equal result,Topic.find_related_tags("foo'bar", :limit => 1)
    end
    def test_tags_count
        list = []
        10.times do |x|
            topic = Topic.new(:name => "Topic #{x}")
            topic.save
            list << topic
        end
        tags = []
        10.times do |x|
            tags << "Tag #{x}"
        end
        10.times do |x|
            list[x].tag tags
            tags.pop
        end
        result = {"Tag 1"=>9, "Tag 2"=>8, "Tag 3"=>7, "Tag 4"=>6,
                "Tag 5"=>5, "Tag 6"=>4, "Tag 7"=>3, "Tag 8"=>2,
                    "Tag 9"=>1, "Tag 0"=>10}
        assert_equal result , Topic.tags_count
        sorted_by_name = result.keys.collect{|key| [key,result[key]]}.sort{|a,b| a[0] <=> b[0]}
        sorted_by_count = result.keys.collect{|key| [key,result[key]]}.sort{|a,b| a[1] <=> b[1]}
        assert_equal sorted_by_name, Topic.tags_count(:sort_list => Proc.new {|list| list.sort{|a,b| a[0] <=> b[0]}})
        assert_equal sorted_by_count, Topic.tags_count(:sort_list => Proc.new {|list| list.sort{|a,b| a[1] <=> b[1]}})

        assert_equal result , Topic.tag_count
        assert_equal sorted_by_name, Topic.tag_count(:sort_list => Proc.new {|list| list.sort{|a,b| a[0] <=> b[0]}})
        assert_equal sorted_by_count, Topic.tag_count(:sort_list => Proc.new {|list| list.sort{|a,b| a[1] <=> b[1]}})
    end
    def test_simple_tag
        assert_equal [],@topic.tags
        @topic.tag "Rails"
        assert_equal ["Rails"], @topic.tag_names
        list = ["Mike","John","Sam"]
        @topic.tag list, :clear => true
        assert_equal list, @topic.tag_names
        @topic.tag "foo'bar,baz", :separator => "," , :clear =>true
        assert_equal ["foo'bar","baz"] , @topic.tag_names

        @topic.tag_remove "foo'bar"
        assert_equal ["baz"] , @topic.tag_names

    end
    def test_join_tag
        assert_equal [], @first_person.tags
        @first_person.tag "Employee", :attributes => { :created_by_id => @second_person.id}
        assert_equal ["Employee"], @first_person.tag_names
        @topic.tag_remove "Employee"
        assert_equal [] , @topic.tag_names
    end
    def test_join_tag_clear_tags!
        assert_equal [], @first_person.tags
        @first_person.tag "Employee", :attributes => { :created_by_id => @second_person.id}
        assert_equal ["Employee"], @first_person.tag_names
        @first_person.clear_tags!
        assert_equal 0 , Topic.count_by_sql("SELECT COUNT(*) FROM tag_people")
    end
    def test_simple_clear_tags!
        assert_equal [],@topic.tags
        assert_equal 0 , Topic.count_by_sql("SELECT COUNT(*) FROM tags_topics")
        @topic.tag "Rails"
        assert_equal 1 , Topic.count_by_sql("SELECT COUNT(*) FROM tags_topics")
        assert_equal ["Rails"], @topic.tag_names
        @topic.clear_tags!
        assert_equal [],@topic.tags
        assert_equal 0 , Topic.count_by_sql("SELECT COUNT(*) FROM tags_topics")
    end
    def test_simple_tagged_with?
        @topic.tag("Ruby Rails")
        assert @topic.tagged_with?("Ruby")
        assert !@topic.tagged_with?("Mike")
    end
    def test_simple_tagged_with_all?
        @topic.tag("Ruby Rails")
        assert @topic.tagged_with_all?("Ruby")
        assert @topic.tagged_with_all?("Rails Ruby")
    end
    def test_simple_tagged_with_any?
        @topic.tag("Ruby Rails")
        assert @topic.tagged_with_any?("Ruby")
        assert @topic.tagged_with_any?("Rails Ruby")
        assert @topic.tagged_with_any?("Rails Ruby Mike")
        assert @topic.tagged_with_any?("Sam Rails Ruby Mike")
    end
    def test_join_tagged_with?
        @first_person.tag("Employee Manager")
        assert @first_person.tagged_with?("Employee")
        assert !@first_person.tagged_with?("Mike")
    end
    def test_join_tagged_with_all?
        @first_person.tag("Employee Manager")
        assert @first_person.tagged_with_all?("Employee")
        assert @first_person.tagged_with_all?("Manager Employee")
    end
    def test_join_tagged_with_any?
        @first_person.tag("Employee Manager")
        assert @first_person.tagged_with_any?("Employee")
        assert @first_person.tagged_with_any?("Manager Employee")
        assert @first_person.tagged_with_any?("Manager Employee Mike")
        assert @first_person.tagged_with_any?("Sam Manager Employee Mike")
    end

end




################################
########OLD UNIT TEST CODE######
################################
#ActiveRecord::Base.connection.drop_table :keywords rescue nil
#ActiveRecord::Base.connection.drop_table :keywords_companies rescue nil
#ActiveRecord::Base.connection.drop_table :tags_posts rescue nil

#ActiveRecord::Base.connection.create_table :tags do |t|
#  t.column @@tag_table_column_name , :string
#end
#
#ActiveRecord::Base.connection.create_table :tags_topics, :id => false do |t|
#  t.column :tag_id, :integer
#  t.column :topic_id, :integer
#  t.column :created_at, :datetime
#end
#
#ActiveRecord::Base.connection.create_table :keywords do |t|
#  t.column :name, :string
#end
#
#ActiveRecord::Base.connection.create_table :keywords_companies, :id => false do |t|
#  t.column :keyword_id, :integer
#  t.column :company_id, :integer
#   acts_as_list :scope => :person
#end
#
#ActiveRecord::Base.connection.create_table :tags_posts do |t|
#  t.column :tag_id, :integer
#  t.column :post_id, :integer
#  t.column :created_at, :datetime
#  t.column :created_by_id, :integer  
#  t.column :position, :integer
#end
#
#class Tag < ActiveRecord::Base; end
#class Topic < ActiveRecord::Base
#  acts_as_taggable
#end
#
#class Keyword < ActiveRecord::Base; end
#  
#class Company < ActiveRecord::Base
#  acts_as_taggable :collection => :keywords, :tag_class_name =>  'Keyword'
#end
#
#class Firm < Company; end
#class Client < Company; end
#
#class Post < ActiveRecord::Base
#  acts_as_taggable :join_class_name => 'TagPost'
#end
#
#class TagPost
#  acts_as_list :scope => :post
#  
#  def before_save
#    self.created_by_id = rand(3) + 1
#  end
#end
#
#class Order < ActiveRecord::Base
#end
#
#class ActAsTaggableTest < Test::Unit::TestCase
#
#  def test_singleton_methods
#    assert !Order.respond_to?(:find_tagged_with)  
#    assert Firm.respond_to?(:find_tagged_with)  
#    assert Firm.respond_to?(:cloud)  
#    assert Post.respond_to?(:find_tagged_with)  
#    assert Post.respond_to?(:cloud)  
#    assert Topic.respond_to?(:find_tagged_with)  
#    assert Topic.respond_to?(:tag_count)  
#    assert Topic.respond_to?(:tags_count)  
#    assert Topic.respond_to?(:cloud)  
#  end
#  
#  def test_with_defaults
#    test_tagging(Topic.find(:first), Tag, :tags)
#  end
#
#  def test_with_non_defaults
#    test_tagging(Company.find(:first), Keyword, :keywords)
#  end
#
#  def test_tag_with_new_object
#    topic = Topic.new
#    topic.tag 'brazil rio beach'
#    topic.save
#  end
#  
#  def test_tagging_with_join_model
#    Tag.delete_all
#    TagPost.delete_all
#    post = Post.find(:first)
#    tags = %w(brazil rio beach)
#    
#    post.tag(tags)
#    tags.each { |tag| assert post.tagged_with?(tag) }
#
#    post.save
#    post.tags.reload
#    tags.each { |tag| assert post.tagged_with?(tag) }
#    
#    posts = Post.find_tagged_with(:any => 'brazil sampa moutain')
#    assert_equal posts[0], post
#    
#    posts = Post.find_tagged_with(:all => 'brazil beach')
#    assert_equal posts[0], post
#    
#    posts = Post.find_tagged_with(:all => 'brazil rich')
#    assert_equal 0, posts.size
#    
#    posts = Post.find_tagged_with(:all => 'brazil', :conditions => [ 'tags_posts.position = ?', 1])
#    assert_equal posts[0], post
#    
#    posts = Post.find_tagged_with(:all => 'rio', :conditions => [ 'tags_posts.position = ?', 2])
#    assert_equal posts[0], post
#
#    posts = Post.find_tagged_with(:all => 'beach', :conditions => [ 'tags_posts.position = ?', 3])
#    assert_equal posts[0], post
#  end
#
#  def test_tags_count_with_join_model  
#    p1 = Post.create(:title => 'test1')
#    p2 = Post.create(:title => 'test2')    
#    p3 = Post.create(:title => 'test3')    
#     
#    p1.tag 'a b c d'
#    p2.tag 'a c e f'
#    p3.tag 'a c f g'
#    
#    counts = Post.tags_count :count => '>= 2', :limit => 2
#    assert_equal counts.keys.size, 2    
#    counts.each { |tag, count| assert count >= 2 }
#    assert counts.keys.include?('a')    
#    assert counts.keys.include?('c')    
#  end
#  
#  def test_tags_count
#    t1 = Topic.create(:title => 'test1')
#    t2 = Topic.create(:title => 'test2')    
#    t3 = Topic.create(:title => 'test3')    
#     
#    t1.tag 'a b c d'
#    t2.tag 'a c e f'
#    t3.tag 'a c f g'
#    
#    count = Topic.tags_count    
#    assert_equal 3, count['a']
#    assert_equal 1, count['b']
#    assert_equal 3, count['c']
#    assert_equal 1, count['d']
#    assert_equal 1, count['e']
#    assert_equal 2, count['f']
#    assert_equal 1, count['g']
#    assert_equal nil, count['h']
#
#    count = Topic.tags_count :count => '>= 2'    
#    assert_equal 3, count['a']
#    assert_equal nil, count['b']
#    assert_equal 3, count['c']
#    assert_equal nil, count['d']
#    assert_equal nil, count['e']
#    assert_equal 2, count['f']
#    assert_equal nil, count['g']
#    assert_equal nil, count['h']
#    
#    t4 = Topic.create(:title => 'test4')    
#    t4.tag 'a f'
#    
#    count = Topic.tags_count :limit => 3    
#    assert_equal 4, count['a']
#    assert_equal nil, count['b']
#    assert_equal 3, count['c']
#    assert_equal nil, count['d']
#    assert_equal nil, count['e']
#    assert_equal 3, count['f']
#    assert_equal nil, count['g']
#    assert_equal nil, count['h']
#    
#    raw = Topic.tags_count :raw => true
#    assert_equal 7, raw.size
#    assert_equal Array, raw.class
#    assert_equal 'a', raw.first[@@tag_table_column_name.to_s]
#    assert_equal '4', raw.first['count']
#    assert_not_nil raw.first['id']
#    assert_equal 'g', raw.last[@@tag_table_column_name.to_s]
#    assert_equal '1', raw.last['count']
#    assert_not_nil raw.last['id']
#  end
#  
#  def test_find_related_tagged
#    t1, t2, t3, t4, t5, t6 = create_test_topics
#
#    assert_equal [ t4, t2, t3 ], t1.tagged_related(:limit => 3)
#    assert_equal [ t5, t1, t3 ], t2.tagged_related(:limit => 3)
#    assert_equal [ t1, t4, t6 ], t3.tagged_related(:limit => 3)
#    assert_equal [ t1, t3, t6 ], t4.tagged_related(:limit => 3)
#    assert_equal [ t2, t1, t3 ], t5.tagged_related(:limit => 3)
#    assert_equal [ t1, t3, t4 ], t6.tagged_related(:limit => 3)
#  end
#
#  def test_find_related_tags
#    t1, t2, t3, t4, t5, t6 = create_test_topics
#    
#    tags = Topic.find_related_tags('rome walking')
#    assert_equal 2, tags['greatview']
#    assert_equal 4, tags['clean']
#    assert_equal 2, tags['mustsee']
#  end
#  
#  def test_find_tagged_with_on_subclasses
#    firm = Firm.find(:first)
#    firm.tag 'law'
#    firms = Firm.find_tagged_with :any => 'law'
#    assert_equal firm, firms[0]
#    assert_equal 1, firms.size
#  end
#  
#  def test_find_tagged_with_any
#    topic1 = Topic.create(:title => 'test1')
#    topic2 = Topic.create(:title => 'test2')    
#    topic3 = Topic.create(:title => 'test3')    
#    
#    topic1.tag('a b c'); topic1.save
#    topic2.tag('a c e'); topic2.save
#    topic3.tag('c d e'); topic3.save
#    
#    topics = Topic.find_tagged_with(:any => 'x y z')
#    assert_equal 0, topics.size
#    
#    topics = Topic.find_tagged_with(:any => 'a b c d e x y z')
#    assert_equal 3, topics.size
#    assert topics.include?(topic1)
#    assert topics.include?(topic2)
#    assert topics.include?(topic3)
#
#    topics = Topic.find_tagged_with(:any => 'a z')
#    assert_equal 2, topics.size
#    assert topics.include?(topic1)   
#    assert topics.include?(topic2)
#    
#    topics = Topic.find_tagged_with(:any => 'b')
#    assert_equal 1, topics.size
#    assert topics.include?(topic1)   
#    
#    topics = Topic.find_tagged_with(:any => 'c')
#    assert_equal 3, topics.size
#    assert topics.include?(topic1)   
#    assert topics.include?(topic2)   
#    assert topics.include?(topic3)   
#
#    topics = Topic.find_tagged_with(:any => 'd')
#    assert_equal 1, topics.size
#    assert topics.include?(topic3)   
#
#    topics = Topic.find_tagged_with(:any => 'e')
#    assert_equal 2, topics.size
#    assert topics.include?(topic2)   
#    assert topics.include?(topic3)   
#  end
#
#  def test_find_tagged_with_all
#    topic1 = Topic.create(:title => 'test1')
#    topic2 = Topic.create(:title => 'test2')    
#    topic3 = Topic.create(:title => 'test3')    
#    
#    topic1.tag('a b c'); topic1.save
#    topic2.tag('a c e'); topic2.save
#    topic3.tag('c d e'); topic3.save
#    
#    topics = Topic.find_tagged_with(:all => 'a b d')
#    assert_equal 0, topics.size
#
#    topics = Topic.find_tagged_with(:all => 'a c')
#    assert_equal 2, topics.size
#    assert topics.include?(topic1)   
#    assert topics.include?(topic2)
#
#    topics = Topic.find_tagged_with(:all => 'a+c', :separator => '+')
#    assert_equal 2, topics.size
#    assert topics.include?(topic1)   
#    assert topics.include?(topic2)
#    
#    topics = Topic.find_tagged_with(:all => 'c e')
#    assert_equal 2, topics.size
#    assert topics.include?(topic2)   
#    assert topics.include?(topic3)   
#    
#    topics = Topic.find_tagged_with(:all => 'c')
#    assert_equal 3, topics.size
#    assert topics.include?(topic1)   
#    assert topics.include?(topic2)   
#    assert topics.include?(topic3)   
#
#    topics = Topic.find_tagged_with(:all => 'a b c')
#    assert_equal 1, topics.size
#    assert topics.include?(topic1)   
#
#    topics = Topic.find_tagged_with(:all => 'a c e')
#    assert_equal 1, topics.size
#    assert topics.include?(topic2)   
#  end
#
#  def test_tag_cloud
#    t1, t2, t3, t4, t5, t6 = create_test_topics
#    
#    tags = Topic.tags_count
#    assert_equal 9, tags.size
#
#    Topic.cloud(tags, ['1', '2', '3', '4', '5', '6']) do |tag, cat|
#      case tag
#        when 'rome':      assert_equal cat, '6'
#        when 'luxury':    assert_equal cat, '3'
#        when 'clean':     assert_equal cat, '6'
#        when 'mustsee':   assert_equal cat, '3'
#        when 'greatview': assert_equal cat, '3'
#        when 'italian':   assert_equal cat, '2'
#        when 'spicy':     assert_equal cat, '2'
#        when 'goodwine':  assert_equal cat, '1'
#        when 'wine':      assert_equal cat, '1'
#        else
#          flunk 'Unexpected Tag/Category pair'
#      end
#    end
#  end
#    
#  private
#  def test_tagging(tagged_object, tag_model, collection)
#    tag_model.delete_all
#    assert_equal 0, tag_model.count
#    
#    tagged_object.tag_names << 'rio brazil'    
#    tagged_object.save    
#    
#    assert_equal 2, tag_model.count
#    assert_equal 2, tagged_object.send(collection).size
#
#    tagged_object.tag_names = 'beach surf'    
#    assert_equal 4, tag_model.count
#    assert_equal 2, tagged_object.send(collection).size
#        
#    tagged_object.tag_names.concat 'soccer+pele', :separator => '+'    
#    assert_equal 6, tag_model.count
#    assert_equal 4, tagged_object.send(collection).size
#    
#    tag_model.delete_all
#    assert_equal 0, tag_model.count
#    tagged_object.send(collection).reload
#        
#    tagged_object.tag_names = 'dhh'    
#    assert_equal 1, tag_model.count
#    assert_equal 1, tagged_object.send(collection).size
#    
#    tagged_object.tag 'dhh rails my', :clear => true
#    
#    assert_equal 3, tag_model.count
#    assert_equal 3, tagged_object.send(collection).size
#    
#    tagged_object.tag 'dhh dhh ruby tags', :clear => true
#    assert_equal 5, tag_model.count    
#    assert_equal 3, tagged_object.send(collection).size
#    
#    tagged_object.tag 'tagging, hello, ruby', :separator => ','
#    assert_equal 7, tag_model.count
#    assert_equal 5, tagged_object.send(collection).size
#
#    all_tags = %w( dhh rails my ruby tags tagging hello )
#    first_tags = %w( dhh ruby tags tagging hello )
#    
#    tagged_object.send(collection).reload
#    assert_equal first_tags, tagged_object.tag_names
#    all_tags.each do |tag_name|
#      tag_record = tag_model.find(:first,:conditions=>["#{@@tag_table_column_name.to_s} = ?",tag_name])
#      assert_not_nil tag_record
#      
#      if first_tags.include?(tag_name)
#        assert tagged_object.send(collection).include?(tag_record) 
#        assert tagged_object.tagged_with?(tag_name)
#      end
#    end
#  end
#
#  def create_test_topics 
#    t1 = Topic.create(:title => 't1')
#    t2 = Topic.create(:title => 't2')    
#    t3 = Topic.create(:title => 't3')    
#    t4 = Topic.create(:title => 't4')    
#    t5 = Topic.create(:title => 't5')    
#    t6 = Topic.create(:title => 't6')    
#    
#    t1.tag('rome, luxury, clean, mustsee, greatview', :separator => ','); t1.save
#    t2.tag('rome, luxury, clean, italian, spicy, goodwine', :separator => ','); t2.save
#    t3.tag('rome, walking, clean, mustsee', :separator => ','); t3.save
#    t4.tag('rome, italy, clean, mustsee, greatview', :separator => ','); t4.save
#    t5.tag('rome, luxury, clean, italian, spicy, wine', :separator => ','); t5.save
#    t6.tag('rome, walking, clean, greatview', :separator => ','); t6.save
#    
#    [ t1, t2, t3, t4, t5, t6 ]     
#  end
#end
