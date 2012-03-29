module Insectdb
class Mrna < ActiveRecord::Base
  has_and_belongs_to_many :segments

  def codons_btwn( start, stop )
    seq.each_slice(3)
       .select{|codon| (codon[0][0]>=start) && (codon[-1][0]<=stop) }
       .map{|codon| codon.map(&:last).join}
  end

  def codons_with_coords_btwn( start, stop )
    seq.each_slice(3)
       .select{|codon| (codon[0][0]>=start) && (codon[-1][0]<=stop) }
  end

  # Get the complete cDNA for thir mRNA.
  #
  # @return [String] 'ATGCCCGTAAAGTTCGATTAG'
  def seq
    s = segments.order('start')
                .map{|s| s.ref_seq.positions.zip(s.ref_seq.nuc_seq.split(""))}
                .flatten(1)
    strand == '+' ? s : s.reverse
  end

  def self.seed( path )
    File.open(File.join(path,'mrnas'),'r') do |f|
      f.lines.each do |l|
        l = l.chomp.split
        seg = self.new do |seg|
          seg.id = l[0]
          seg.chromosome = l[1]
          seg.strand = l[2]
          seg.start = l[3]
          seg.stop = l[4]
          seg.save
        end
      end
    end
  end

end
end
