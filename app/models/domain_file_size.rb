# Copyright (C) 2009 Pascal Rettig.

class DomainFileSize < DomainModel 

  validates_presence_of :name, :size_name
  validates_uniqueness_of :name, :size_name
  
  validates_format_of :size_name, :with => /^[A-Za-z0-9\-]+$/, :message => 'can only contain numbers, letters and dashes (-)'
  
  serialize :operations
  
  has_options :operation, 
    [ ['Thumbnail','thumbnail'],
      ['Cropped Thumbnail','cropped_thumbnail'],
      ['Resize','resize'],
      ['Window','window']]
      
  @@gravity_options =  [ ['Center', 'CenterGravity'],
                             ['Top Left','NorthWestGravity'],
                             ['Top','NorthGravity'],
                             ['Top Right','NorthEastGravity'],
                             ['Right','EastGravity'],
                             ['Bottom Right','SouthEastGravity'],
                             ['Bottom','SouthGravity'],
                             ['Bottom Left','SouthWestGravity'],
                             ['Left','WestGravity'] ]
  cattr_accessor :gravity_options

  def validate #:nodoc:all
    self.errors.add_to_base("One or more operation options are invalid") if !operations_valid?
  end
  
  def operations
    return @operation_cache if @operation_cache
    opts = self.read_attribute(:operations)
    opts ||= []
    @operation_cache = opts.map do |op|
      @@operation_classes[op[:type]].new(op)
    end
  end
  
  def self.new_operation(type)
    @@operation_classes[type].new(:type => type)
  end
  
  def operations=(val)
    val = val.map do |op| 
      op = op.is_a?(Operation) ? op :  @@operation_classes[op[:type]].new(op)
      op.valid?
      op.to_hash.merge(:type => op.operation_name )
    end
    self.write_attribute(:operations,val)
    @operation_cache = nil
  end
  
  def operations_valid?
    ok = true
    self.operations.each do |op|
      ok = false unless op.valid?
    end
    ok
  end

  def final_size
    last_opt = self.operations.last
    if last_opt
      last_opt.final_size
    else
      "0px X opx"
    end
  end

  def self.valid_size?(size)
    return false if size.blank?
    return true if DomainFile.image_sizes_hash[size.to_sym]
    return true if self.custom_sizes[size.to_sym]
    false
  end
  
  def self.custom_sizes
    custom_size_hash = DataCache.get_cached_container("Config",'DomainFileSize')  unless RAILS_ENV == 'test'
    return custom_size_hash if custom_size_hash
    
    custom_size_hash = {}
    DomainFileSize.find(:all).each do |size|
      custom_size_hash[size.size_name.to_sym] = [ size.name, size.final_size ]
    end
    DataCache.put_container("Config",'DomainFileSize',custom_size_hash)  unless RAILS_ENV == 'test'
    return custom_size_hash
  end
  
  def execute(df)
    image=nil
    begin
      result_file = df.abs_filename(self.size_name,true)
      image = Magick::Image::read(df.filename)[0]
      self.operations.each do |operation|
        old_image = image
        image = operation.apply(old_image)
        old_image.destroy! if image != old_image
      end
      FileUtils.mkpath(File.dirname(result_file))
      image.write(result_file)
    rescue Exception => e
      raise e
    end
    df.reload(:lock => true)
    if image
      df.set_size(self.size_name,image.columns,image.rows)
      image.destroy!
    end
    GC.start
    df.save
    return result_file
  end
  
  class Operation < HashModel #:nodoc:all
   attributes :type => nil
  end
  
  class SizeOperation < Operation #:nodoc:all
    attributes :width => nil, :height => nil
    validates_numericality_of :width,:height, :greater_than => 0
    integer_options :width,:height
    
    def final_size
      "#{self.width}px X #{self.height}px"
    end
  end
  
  
    class ThumbnailOperation < SizeOperation #:nodoc:all
      def apply(img)
         img.resize_to_fit!(self.width,self.height)
      end
      
      def operation_name; 'thumbnail'; end
    end
    class CroppedThumbnailOperation < SizeOperation #:nodoc:all
      def operation_name; 'cropped_thumbnail'; end
      attributes :anchor => 'CenterGravity'
      
      has_options :anchor, DomainFileSize.gravity_options
      validates_inclusion_of :anchor, :in => anchor_options_hash.keys
      def apply(img)
         img.resize_to_fill!(self.width,self.height,"Magick::#{self.anchor}".constantize)
      end
      
    end
    class ResizeOperation < SizeOperation #:nodoc:all
      def operation_name; 'resize'; end
      def apply(img)
          img.resize(self.width,self.height)
      end
    end
    class WindowOperation < SizeOperation #:nodoc:all
      def operation_name; 'window'; end
      
      attributes :offset_x => 0,:offset_y => 0,:anchor => nil
      validates_numericality_of :offset_y,:offset_y
      integer_options :offset_x,:offset_y

      has_options :anchor, [['None','']] + DomainFileSize.gravity_options
      validates_inclusion_of :anchor, :in => anchor_options_hash.keys, :allow_nil => true
      

      def apply(img)
        if !self.anchor.blank?
          if(img.columns < self.width || img.rows < self.height)
            img
          else
            img.crop("Magick::#{self.anchor}".constantize,self.offset_x,self.offset_y,self.width,self.height,true)
          end
        else
          if(img.columns < self.width || img.rows < self.height)
            img
          else
            img.crop(self.offset_x,self.offset_y,self.width,self.height,true)
          end
        end
      end
    end
  
  @@operation_classes = { 'thumbnail' => ThumbnailOperation,
                          'cropped_thumbnail' => CroppedThumbnailOperation,
                          'resize' => ResizeOperation,
                          'window' => WindowOperation }

  
  
  protected
  
  def apply_operation(image,operation)
    case operation[:type]
    when 'thumbnail':
      image.thumbnail(op[:size].to_i) do |img|
        apply_operations(img,ops,filename)
      end
    when 'resize':
      image.resize(op[:width].to_i,op[:height]) do |img|
        apply_operations(img,ops,filename)
      end
    when 'cropped_thumbnail':
      image.cropped_thumbnail(op[:size].to_i) do |img|
        apply_operations(img,ops,filename)
      end
    when 'crop':
      image.crop(op[:left].to_i,op[:top].to_i,op[:right].to_i,op[:bottom].to_i) do |img|
        apply_operations(img,ops,filename)
      end
    else
      raise 'Invalid Operation'
    end
  end
end
