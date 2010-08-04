require 'yaml'

class WebivaBundler < HashModel
  VERSION = '1.0'

  attr_accessor :importing

  attributes :version => nil, :name => nil, :thumb_id => nil, :domain_files => nil, :modules => nil, :inputs => nil, :creator_id => nil, :bundle_file_id => nil, :replace_same => true

  boolean_options :replace_same

  domain_file_options :thumb_id, :bundle_file_id

  def strict?; true; end

  def validate
    if self.importing
      self.errors.add(:bundle_file_id, 'is missing') unless self.bundle_file
      self.errors.add(:bundle_file_id, 'is invalid') if self.bundle_file && (self.bundle_file.extension != 'webiva' || self.get_bundle_info.nil?)
    else
      self.errors.add(:name, 'is missing') unless self.name
    end
  end

  def data; @data ||= []; end
  def domain_files; @domain_files ||= []; end
  def modules; @modules ||= []; end
  def inputs; @inputs ||= {}; end

  # Meta attributes
  def meta; @meta ||= {}; end
  def author; self.meta['author']; end
  def author=(value); self.meta['author'] = value; end
  def description; self.meta['description']; end
  def description=(value); self.meta['description'] = value; end
  def license; self.meta['license']; end
  def license=(value); self.meta['license'] = value; end

  def add_folder(folder)
    self.domain_files << folder
  end

  def add_input(cls, id, hsh={})
    self.inputs["#{cls.to_s}_#{id}"] = (self.inputs["#{cls.to_s}_#{id}"] || {}).merge(hsh.stringify_keys)
  end

  def get_new_input_id(cls, id)
    self.inputs["#{cls.to_s}_#{id}"]['id']
  end

  def get_new_input(cls, id)
    self.inputs["#{cls.to_s}_#{id}"]['obj']
  end

  def export_object(obj)
    self.data << {'data' => obj.export_to_bundle(self), 'name' => obj.name, 'handler' => obj.class.to_s.underscore}
  end

  def import_object(info, opts={})
    handler = info['handler'].camelcase.constantize
    handler.import_bundle(self, info['data'], opts)
  end

  def export
    dir = DomainFile.generate_temporary_directory

    folders = self.domain_files.uniq.collect do |folder|
      { 'id' => folder.id,
        'filename' => File.basename(self.export_folder(dir, folder)),
        'name' => folder.name
      }
    end

    self.version = VERSION

    manifest = {
      'version' => self.version,
      'name' => self.name,
      'meta' => self.meta,
      'data' => 'data.yml',
      'folders' => folders,
      'modules' => self.modules.uniq,
      'thumb' => self.thumb ? self.thumb.name : nil,
      'inputs' => self.inputs
    }

    File.open("#{dir}/data.yml", "w") { |fd| fd.write(YAML.dump({'data' => self.data})) }

    File.open("#{dir}/MANIFEST.yml", "w") { |fd| fd.write(YAML.dump(manifest)) }

    File.copy(self.thumb.filename, "#{dir}/#{self.thumb.name}") if self.thumb

    bundle_filename = name.downcase.gsub(/[ _]+/,"_").gsub(/[^a-z+0-9_]/,"") + ".webiva"
    File.unlink("#{dir}/../#{bundle_filename}") if File.exists?("#{dir}/../#{bundle_filename}")
    `cd #{dir}; tar zcf ../#{bundle_filename} *`

    File.open("#{dir}/../#{bundle_filename}") do |fd|
      bundle = DomainFile.create :filename => fd, :parent_id => DomainFile.themes_folder.id, :process_immediately => true, :private => true, :creator_id => self.creator_id
      self.bundle_file_id = bundle.id
    end

    File.unlink("#{dir}/../#{bundle_filename}") if File.exists?("#{dir}/../#{bundle_filename}")
    FileUtils.rm_rf(dir)

    self.bundle_file
  end

  def import
    return nil unless self.bundle_file

    self.creator_id ||= bundle_file.creator_id

    dir = DomainFile.generate_temporary_directory
    File.copy(self.bundle_file.filename, "#{dir}/#{self.bundle_file.name}")
    `cd #{dir}; tar zxf #{self.bundle_file.name}`

    manifest = YAML.load_file("#{dir}/MANIFEST.yml")
    self.name = manifest['name']
    @meta = manifest['meta']
    self.inputs = manifest['inputs']
    self.modules = manifest['modules']

    unless manifest['folders'].empty?
      theme_folder = self.get_folder(self.name, DomainFile.themes_folder.id)
      self.import_folder(dir, manifest['folders'].shift, theme_folder)

      manifest['folders'].each do |info|
        folder = self.get_folder(info['name'], theme_folder.id)
        self.import_folder(dir, info, folder)
      end
    end

    @data = YAML.load_file("#{dir}/#{manifest['data']}")['data']

    self.data.each { |info| self.import_object(info, :replace_same => self.replace_same) }

    FileUtils.rm_rf(dir)
  end

  def get_folder(name, parent_id)
    folder = nil
    folder = DomainFile.find_by_file_type_and_parent_id_and_name('fld', parent_id, name) if self.replace_same
    folder ||= DomainFile.create(:name => name, :parent_id => parent_id, :file_type => 'fld', :creator_id => self.creator_id)
    folder
  end

  def export_folder(dir, folder)
    return nil unless folder.file_type == 'fld'
    
    dir = "#{dir}/#{folder.id}/"
    FileUtils.mkpath(dir)
    folder.children_cp(dir)
    
    dest_filename = folder.id.to_s + '_' + folder.name.downcase.gsub(/[ _]+/,"_").gsub(/[^a-z+0-9_]/,"") + ".zip"
    `cd #{dir}; zip -r ../#{dest_filename} *`
    FileUtils.rm_rf(dir)
    dest_filename
  end

  def import_folder(dir, info, theme_folder)
    self.add_input(DomainFile, info['id'], {'id' => theme_folder.id, 'obj' => theme_folder})
    dir = "#{dir}/#{info['id']}"
    FileUtils.mkpath(dir)
    `cd #{dir}; unzip ../#{info['filename']}`
    file_ids = DomainFile.new(:creator_id => self.creator_id).extract_directory(dir, theme_folder.id)
    DomainFile.find(file_ids).each { |file| file.post_process!(false) }
    DomainFile.find(file_ids).map(&:replace_same) if self.replace_same
    FileUtils.rm_rf(dir)
  end

  def get_bundle_info
    dir = DomainFile.generate_temporary_directory
    File.copy(self.bundle_file.filename, "#{dir}/#{self.bundle_file.name}")
    `cd #{dir}; tar zxf #{self.bundle_file.name} MANIFEST.yml`

    unless File.exists?("#{dir}/MANIFEST.yml")
      FileUtils.rm_rf(dir)
      return nil
    end

    manifest = YAML.load_file("#{dir}/MANIFEST.yml")
    self.version = manifest['version']
    self.name = manifest['name']
    @meta = manifest['meta']
    self.inputs = manifest['inputs']
    self.modules = manifest['modules']

    if ! manifest['thumb'].blank? && self.thumb.nil?
      thumbnail_folder = DomainFile.find(:first,:conditions => "name = 'Thumbnails' and parent_id = #{DomainFile.themes_folder.id}") || DomainFile.create(:name => 'Thumbnails', :parent_id => DomainFile.themes_folder.id, :file_type => 'fld')
      `cd #{dir}; tar zxf #{self.bundle_file.name} #{manifest['thumb']}`
      File.open("#{dir}/#{manifest['thumb']}", "r") do |fd|
        self.thumb_id = DomainFile.create(:filename => fd, :parent_id => thumbnail_folder.id, :process_immediately => true).id
      end
    end

    FileUtils.rm_rf(dir)

    manifest
  end

  def run_worker
    DomainModel.run_worker(self.class.to_s, nil, :import_bundle, :bundle_file_id => self.bundle_file_id, :inputs => self.inputs, :replace_same => self.replace_same)
  end

  def self.import_bundle(opts={})
    bundler = WebivaBundler.new :bundle_file_id => opts[:bundle_file_id], :inputs => opts[:inputs], :replace_same => opts[:replace_same]
    bundler.import
  end
end
