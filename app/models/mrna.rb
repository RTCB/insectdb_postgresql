module Insectdb
class Mrna < ActiveRecord::Base
  has_and_belongs_to_many :segments

  def self.clear_cache
    Insectdb.peach(Mrna.all) do |m|
      m.update_attributes("_seq" => nil)
    end
    true
  end

  # @return [Array] ['ATG','GGT','TTA','GCT']
  def codons_btwn( start, stop )
    case strand
    when '+'
      seq.each_slice(3)
        .select{ |codon| (codon[0][0]>=start) && (codon[-1][0]<=stop) }
        .map{ |codon| Codon.new(codon) }
    when '-'
      seq.each_slice(3)
        .select{ |codon| (codon[0][0]<=stop) && (codon[-1][0]>=start) }
        .map{ |codon| Codon.new(codon) }
    end
  end

  def seq
    if _seq.nil?
      s = segments.order('start')
                  .map{|s| s.ref_seq.positions.zip(s.ref_seq.nuc_seq.split(""))}
                  .flatten(1)
      update_attributes("_seq" => JSON.dump(strand == '+' ? s : s.reverse))
    end
    JSON.parse(_seq)
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
