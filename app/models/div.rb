module Insectdb
class Div < ActiveRecord::Base

  # default_scope where("dmel_sig_count >= 150 and snp = false and dsim_dyak = true and dmel_dsim = false")

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
