module Insectdb
class GenesMrnas < ActiveRecord::Base
  self.table_name = 'genes_mrnas'

  validates :gene_id,
            :presence => true,
            :numericality => { :only_integer => true }

  validates :mrnas_id,
            :presence => true,
            :numericality => { :only_integer => true }
end
end
