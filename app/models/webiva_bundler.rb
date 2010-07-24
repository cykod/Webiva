
class WebivaBundler

  # Bundle file looks like
  # MANIFEST is a YAML file
  # theme is a SiteTemplate
  # returns a DomainFile that is the bundle file.
  def export(name, site_template, meta={})
    meta = meta.stringify_keys.merge('name' => name)
    theme = site_template.export

    dir = DomainFile.generate_temporary_directory

    folders = site_template.all_folders.collect do |folder|
      { 'id' => folder.id,
        'filename' => File.basename(self.export_folder(dir, folder)),
        'name' => folder.name
      }
    end

    manifest = {
      'meta' => meta,
      'theme' => 'theme.yml',
      'folders' => folders
    }

    File.open("#{dir}/theme.yml", "w") { |fd| fd.write(YAML.dump({'theme' => theme})) }

    File.open("#{dir}/MANIFEST", "w") { |fd| fd.write(YAML.dump(manifest)) }

    bundle_filename = name.downcase.gsub(/[ _]+/,"_").gsub(/[^a-z+0-9_]/,"") + ".bundle"
    `cd #{dir}; tar zcf ../#{bundle_filename} *`

    file = File.open("#{dir}/../#{bundle_filename}")
    bundle = DomainFile.create :filename => file, :parent_id => DomainFile.themes_folder.id, :process_immediately => true, :private => true, :special => 'bundle'
  
    FileUtils.rm_rf(dir)
    FileUtils.rm_rf("#{dir}/../#{bundle_filename}")

    bundle
  end

  # bundle_file is a DomainFile
  def import(bundle_file)
    dir = DomainFile.generate_temporary_directory
    File.copy(bundle_file.filename, "#{dir}/#{bundle_file.name}")
    `cd #{dir}; tar zxf #{bundle_file.name}`

    manifest = YAML.load_file("#{dir}/MANIFEST")

    meta = manifest['meta']

    folders = {}
    unless manifest['folders'].empty?
      theme_folder = DomainFile.create(:name => meta['name'], :parent_id => DomainFile.themes_folder.id, :file_type => 'fld')
      primary_folder = manifest['folders'].shift
      DomainFile.new(:filename => "#{dir}/#{primary_folder['filename']}", :parent_id => theme_folder.id).extract
      folders[primary_folder['id']] = theme_folder

      manifest['folders'].each do |folder_id, info|
        folder = DomainFile.create(:name => info['name'], :parent_id => theme_folder.id, :file_type => 'fld')
        DomainFile.new(:filename => "#{dir}/#{info['filename']}", :parent_id => folder.id).extract
        folders[info['id']] = folder
      end
    end

    theme = YAML.load_file("#{dir}/#{manifest['theme']}")
    SiteTemplate.import theme['theme'], folders
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
end
