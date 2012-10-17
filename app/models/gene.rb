module Insectdb
class Gene < ActiveRecord::Base

  # has_and_belongs_to_many :mrnas

  validates :flybase_id,
            :presence => true

end
end
