module Insectdb
class Gene < ActiveRecord::Base

  has_and_belongs_to_many :mrnas

  validates :mrnas_id,
            :presence => true,
            :numericality => { :only_integer => true }

  validates :segment_id,
            :presence => true,
            :numericality => { :only_integer => true }

end
end
