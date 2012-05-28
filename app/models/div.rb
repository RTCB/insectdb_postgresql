module Insectdb
class Div < Reference

  default_scope where("dmel_sig_count >= 150 and snp = false and dsim_dyak = true and dmel_dsim = false")

  # Return Divs segregating at particular positions on chromosome.
  #
  # @example
  #   Div.at_poss('2R', [1,2,3]) => [nil, ReferenceObj, nil]
  #
  # @return [Array]
  def self.at_poss( chr, poss )
    query =
      self.where(
                  "chromosome = ?  and
                   position in (?) and
                   dsim_dyak=true  and
                   dmel_dsim=false and
                   dmel != 'N'",
                   CHROMOSOMES[chr], poss
                )

    poss.map do |pos|
      query.find{|div| div.position == pos}
    end
  end

  def self.count_at_poss( chr, poss )
    self.where(
               "chromosome = ? and
                position in (?) and
                dmel_dsim = false and
                dmel != 'N'",
                CHROMOSOMES[chr], poss
    ).count
  end

  def self.count_at_poss_with_nucs( chr, poss, dmel_nuc, simyak_nuc )
    Div.where(
      "chromosome = ? and
       position in (?) and
       dmel = ? and dsim = ?",
       CHROMOSOMES[chr], poss, dmel_nuc, simyak_nuc
    ).count
  end

  def self.alleles_at_poss( strand, chr, poss )
    self.at_poss(chromosome,poss)
        .map{|div| div ? div.alleles(strand) : nil }
  end

  def alleles( strand = '+' )
    [dmel, dsim].map{|n| strand == '+' ? n : Contig.complement(n) }
  end

end
end
