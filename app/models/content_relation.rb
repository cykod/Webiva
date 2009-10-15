

class ContentRelation < DomainModel

  belongs_to :entry, :polymorphic => true
  belongs_to :relation, :polymorphic => true

end
