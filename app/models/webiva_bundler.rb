require 'yaml'

class WebivaBundler
  VERSION = '1.0'

  attr_accessor :name, :data, :thumb, :domain_files, :meta, :modules, :inputs, :creator_id

  def initialize
    @data = []
    @inputs = {}
    @meta = {}
    @domain_files = []
    @modules = []
  end

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

  def import_object(info)
    handler = info['handler'].camelcase.constantize
    handler.import_bundle(self, info['data'])
  end

  def export
    dir = DomainFile.generate_temporary_directory

    folders = self.domain_files.uniq.collect do |folder|
      { 'id' => folder.id,
        'filename' => File.basename(self.export_folder(dir, folder)),
        'name' => folder.name
      }
    end

    manifest = {
      'version' => VERSION,
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
    `cd #{dir}; tar zcf ../#{bundle_filename} *`

    file = File.open("#{dir}/../#{bundle_filename}")
    bundle = DomainFile.create :filename => file, :parent_id => DomainFile.themes_folder.id, :process_immediately => true, :private => true, :creator_id => self.creator_id
  
    FileUtils.rm_rf(dir)
    FileUtils.rm_rf("#{dir}/../#{bundle_filename}")

    bundle
  end

  # bundle_file is a DomainFile
  def import(bundle_file)
    self.creator_id ||= bundle_file.creator_id

    dir = DomainFile.generate_temporary_directory
    File.copy(bundle_file.filename, "#{dir}/#{bundle_file.name}")
    `cd #{dir}; tar zxf #{bundle_file.name}`

    manifest = YAML.load_file("#{dir}/MANIFEST.yml")
    self.name = manifest['name']
    self.meta = manifest['meta']
    self.inputs = manifest['inputs']
    self.modules = manifest['modules']

    unless manifest['folders'].empty?
      theme_folder = DomainFile.create(:name => self.name, :parent_id => DomainFile.themes_folder.id, :file_type => 'fld', :creator_id => self.creator_id)
      self.import_folder(dir, manifest['folders'].shift, theme_folder)

      manifest['folders'].each do |info|
        folder = DomainFile.create(:name => info['name'], :parent_id => theme_folder.id, :file_type => 'fld', :creator_id => self.creator_id)
        self.import_folder(dir, info, folder)
      end
    end

    self.data = YAML.load_file("#{dir}/#{manifest['data']}")['data']

    self.data.each { |info| self.import_object(info) }

    FileUtils.rm_rf(dir)
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
    FileUtils.rm_rf(dir)
  end
end
