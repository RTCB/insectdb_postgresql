module Insectdb
class Div < ActiveRecord::Base

  validates :chromosome,
            :presence => true,
            :numericality => { :only_integer => true },
            :inclusion => { :in => [0, 1, 2, 3, 4] }

  validates :position,
            :presence => true,
            :numericality => { :only_integer => true }

  # Public: Create a new record from coordinates on chromosome.
  #
  # chr - The String with chromosome name.
  # pos - The Integere with position on chromosome.
  #
  # Examples:
  #
  #   Insectdb::Div.from_hash('2R', 765986)
  #
  # Returns The Insectdb::Div object.
  def self.from_hash( chr, pos )
    self.create!(
      :chromosome => Insectdb::CHROMOSOMES[chr],
      :position => pos
    )
  end

  # Public: The position is considered divergent if it posesses equal
  #         nucleotides at D.simulans and D.yakuba, but a different one at
  #         D.melanogaster.
  #
  # hash - The Hash with nucleotides,
  #        e.g. {:dmel => 'A', :dsim => 'A', :dyak => 'G'}
  #
  # Examples:
  #
  #   Insectdb::Div.position_is_divergent?({ :dmel => 'A',
  #                                          :dsim => 'G',
  #                                          :dyak => 'G',}) # => true
  #
  #   Insectdb::Div.position_is_divergent?({ :dmel => 'A',
  #                                          :dsim => 'N',
  #                                          :dyak => 'N',}) # => false
  #
  #   Insectdb::Div.position_is_divergent?({ :dmel => 'N',
  #                                          :dsim => 'A',
  #                                          :dyak => 'A',}) # => false
  #
  #   Insectdb::Div.position_is_divergent?({ :dmel => 'N',
  #                                          :dsim => 'N',
  #                                          :dyak => 'N',}) # => false
  #
  #   Insectdb::Div.position_is_divergent?({ :dmel => 'A',
  #                                          :dsim => 'G',
  #                                          :dyak => 'C',}) # => false
  #
  # Returns The Boolean.
  def self.position_is_divergent?( hash )
    (hash[:dsim] == hash[:dyak]) &&
    (hash[:dmel] != hash[:dsim]) &&
    !hash.values.include?('N')
  end

  def self.at_poss( chr, poss )
    query =
      self.where(
                  "chromosome = ?  and
                   position in (?) and
                   dsim_dyak=true  and
                   dmel_dsim=false and
                   dmel != 'N'",
                   Insectdb::CHROMOSOMES[chr], poss
                )

    poss.map { |pos| query.find { |div| div.position == pos }}
  end

  def self.count_at_poss( chr, poss )
    return 0 if poss.empty?
    # timer = nil
    # warn "\nEntering Div::count_at_poss for #{chr} with array of #{poss.size} positions"
    # .tap { |a| warn "Positions array sliced into #{a.count} pieces" }
    # .tap { warn "Processing slices"; timer = Time.now }
    # .tap { warn "Took #{(Time.now - timer).round(4)} seconds"}
    poss.each_slice(100000)
        .map { |sli| self.where( "chromosome = ? and position in (?) and dmel_dsim = false and dmel != 'N'", Insectdb::CHROMOSOMES[chr], sli).count }
        .reduce(:+)
  end

  def self.count_at_poss_with_nucs( chr, poss, dmel_nuc, simyak_nuc, chunk_size = 10000 )
    poss.each_slice(chunk_size).map do |sl|
      Div.where(
        "chromosome = ? and
         position in (?) and
         dmel = ? and dsim = ?",
         Insectdb::CHROMOSOMES[chr], sl, dmel_nuc, simyak_nuc
      ).count
    end.reduce(:+)
  end

  def self.alleles_at_poss( strand, chr, poss )
    self.at_poss(chromosome,poss)
        .map { |div| div ? div.alleles(strand) : nil }
  end

  def alleles( strand = '+' )
    [dmel, dsim].map { |n| strand == '+' ? n : Contig.complement(n) }
  end

end
end
