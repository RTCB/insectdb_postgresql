module Insectdb
class Mrna < ActiveRecord::Base
  serialize :supp, Hash

  has_and_belongs_to_many :genes
  has_and_belongs_to_many :segments

  validates :chromosome,
            :presence => true,
            :numericality => { :only_integer => true },
            :inclusion => { :in => [0, 1, 2, 3, 4] }

  validates :start,
            :presence => true,
            :numericality => { :only_integer => true }

  validates :stop,
            :presence => true,
            :numericality => { :only_integer => true }

  validates :strand,
            :presence => true,
            :inclusion => { :in => %W[ + - ] }

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

end
end
