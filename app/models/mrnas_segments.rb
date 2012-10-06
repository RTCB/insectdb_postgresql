module Insectdb
class MrnasSegments < ActiveRecord::Base
  self.table_name = 'mrnas_segments'

  validates :mrnas_id,
            :presence => true,
            :numericality => { :only_integer => true }

  validates :segment_id,
            :presence => true,
            :numericality => { :only_integer => true }
end
end
