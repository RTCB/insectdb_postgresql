module Insectdb
class Mrna < ActiveRecord::Base
  serialize :supp, Hash

  has_and_belongs_to_many :segments

  def self.clear_cache
    Insectdb.peach(Mrna.all) do |m|
      m.update_attributes("_seq" => nil)
    end
    true
  end

  def self.seed( path )
    File.open(File.join(path),'r') do |f|
      f.lines.each do |l|
        l = l.chomp.split
        Insectdb::Mrna.create!(
          :id         => l[0],
          :chromosome => l[1],
          :strand     => l[2],
          :start      => l[3],
          :stop       => l[4]
        )
      end
    end
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
