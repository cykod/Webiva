
class DummyText

  # Taken from http://www.lipsum.com/feed/html

  @@lipsum_paragraphs = ['Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus luctus aliquet laoreet. Maecenas adipiscing laoreet enim, id molestie sapien dapibus in. Donec eu nunc eget libero convallis posuere. Proin mollis tempus auctor. Etiam commodo tortor in augue luctus sed ullamcorper nibh pulvinar. Phasellus cursus augue vel purus vulputate luctus. Sed cursus massa quis nisl tincidunt eget dapibus tortor scelerisque. Curabitur blandit, arcu ac placerat bibendum, est ligula vehicula nunc, vel suscipit augue erat non mi. Donec mollis blandit enim, rhoncus lacinia nibh tincidunt nec. Suspendisse et orci eros. Phasellus aliquet, mi ac viverra elementum, purus turpis tristique lacus, vel fringilla massa elit vel nibh. Donec rhoncus orci a dui rutrum ac tempor erat eleifend. Integer sagittis eleifend risus, id fermentum eros facilisis id.',
    'Maecenas sodales, justo vel commodo iaculis, erat lectus aliquam justo, vitae egestas metus nibh egestas purus. Donec ac purus id tortor dapibus ullamcorper. Vestibulum et elit suscipit felis placerat varius at eget nulla. Ut nisl magna, auctor id dictum vel, convallis sed urna. Nulla facilisi. Donec ac risus a elit egestas laoreet. Phasellus commodo, quam ut iaculis faucibus, lacus mi pretium sem, non luctus urna nulla a lectus. Donec nec dui nisi. Ut eu ultrices purus. Ut vel quam sapien. Donec eget arcu sem. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nulla dignissim ipsum in velit malesuada sit amet pulvinar odio viverra. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Proin et tellus interdum purus dignissim accumsan non ac ante. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae;',
    'Maecenas gravida leo vel lorem tincidunt vehicula. Vivamus aliquet consectetur erat nec tincidunt. Nullam euismod felis non augue vestibulum id interdum erat bibendum. Donec quam arcu, pretium in varius vel, porttitor id neque. Nunc non mi eu urna semper viverra. Integer a hendrerit magna. Quisque augue dui, sagittis ac venenatis in, tincidunt ut augue. Maecenas lobortis laoreet enim, consequat lacinia risus varius at. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Mauris id ligula nibh, et pellentesque ligula. Morbi in dictum ante. Nullam eros velit, viverra sit amet tristique in, sagittis et lectus. Vestibulum quis purus purus, at convallis libero.',
    'Cras augue nunc, congue eu elementum in, aliquet sit amet neque. Donec luctus tempor condimentum. Phasellus eget nisi at felis tempor condimentum non ac dolor. Nulla mi nunc, luctus nec pretium eu, viverra sit amet ipsum. Sed viverra faucibus condimentum. Pellentesque eget massa mi. Phasellus scelerisque orci eget ante dapibus semper. Nulla sit amet tincidunt lorem. Etiam aliquet semper tortor ac tristique. Sed volutpat consectetur diam, ac pharetra eros faucibus nec. Sed lobortis erat quis massa sollicitudin sed hendrerit dolor semper. Nunc nulla libero, tempus id lacinia sit amet, consectetur quis est. Donec venenatis velit eu mi fermentum ac porta est sollicitudin. Maecenas laoreet, augue eget vulputate vestibulum, leo mi bibendum neque, vel pretium nisl sem a nibh. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris fermentum elit quis risus scelerisque venenatis. Vestibulum vitae eros a neque dignissim pharetra eu eu sem. Ut justo augue, luctus non cursus a, rutrum nec enim. Suspendisse potenti.',
    'Fusce eget ante non nisl euismod auctor vel eleifend metus. Curabitur pretium ullamcorper est, nec aliquet orci dapibus in. Morbi egestas, tortor vel pulvinar rutrum, massa odio feugiat enim, non adipiscing nisi dolor eget tellus. Vestibulum pharetra nulla in purus rhoncus in cursus quam pellentesque. Vestibulum id ipsum erat, a pulvinar nisi. Nunc a sapien massa. Aenean at mauris augue. Phasellus aliquet, magna at vestibulum lacinia, elit nisi pulvinar turpis, eu sollicitudin sapien lorem id felis. Cras ipsum est, tristique quis consequat in, vestibulum eget justo. Mauris sapien quam, aliquet viverra semper consectetur, euismod sed leo. Praesent ultrices pharetra ornare.',
  ]

  def self.paragraph(amount=1, opts={})
    self.create_lipsum({:amount => amount, :what => 'paras', :start => 'no'}.merge(opts))
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
    self.create_lipsum(:amount => amount, :what => 'words', :start => 'no')
  end

  def self.create_lipsum(opts={})
    opts[:what] ||= 'paras'
    opts[:amount] ||= 5
    opts[:start] ||= 'yes'

    case opts[:what]
    when 'paras'
      return @@lipsum_paragraphs[opts[:start] == 'yes' ? 0 : rand(@@lipsum_paragraphs.size)]
    when 'words'
      para = @@lipsum_paragraphs[opts[:start] == 'yes' ? 0 : rand(@@lipsum_paragraphs.size)]
      return para.split(' ')[0..opts[:amount]].join(' ')
    end

    'Lorem ipsum'
  end
end
