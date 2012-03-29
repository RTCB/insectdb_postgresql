module Insectdb
class Reference < ActiveRecord::Base
  self.table_name = 'reference'

  CHROMOSOMES = {1 => '2R',
                 2 => '2L',
                 3 => '3R',
                 4 => '3L',
                 5 => 'X'}

  def self.upload_reference( path )
    Parallel.each(self::CHROMOSOMES.values,
                  :in_processes => 5) do |chr|
      enums =
        [
          "drosophila_melanogaster/dm3_#{chr}.fa.gz",
          "drosophila_simulans/droSim1_#{chr}.fa.gz",
          "drosophila_yakuba/droYak2_#{chr}.fa.gz"
        ].map{|f| Insectdb::SeqEnum.new(File.join(path, f))}

      enums = [:dmel,:dsim,:dyak].zip(enums).to_hash

      enums[:dmel].length.times do |ind|
        dmel = enums[:dmel].next
        dsim = enums[:dsim].next
        dyak = enums[:dyak].next
        doc = {
          :position => ind+1,
          :chromosome => chr,
          :dmel => dmel,
          :dsim => dsim,
          :dyak => dyak,
          :dmel_dsim => self.na_eq?(dmel,dsim),
          :dmel_dyak => self.na_eq?(dmel,dyak),
          :dsim_dyak => self.na_eq?(dsim,dyak)
        }
        self.create!(doc)
      end
    end
  end

  def self.na_eq?( char_1, char_2 )
    (%W[A C G T].include?(char_1)) &&
    (%W[A C G T].include?(char_2)) &&
    (char_1 == char_2)
  end

end
end
