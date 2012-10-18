module Insectdb
class Segment < ActiveRecord::Base
  serialize :_ref_seq

  self.inheritance_column = 'inheritance_type'
  has_and_belongs_to_many :mrnas

  scope :alt, where(:type => 'coding(alt)')
  scope :const, where(:type => 'coding(const)')
  scope :int, where(:type => 'intron')
  scope :coding, where("type != 'intron'")

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

  validates :length,
            :presence => true,
            :numericality => { :only_integer => true }

  validates :type,
            :presence => true


  # Public: Remove all noncoding segments.
  #
  # Returns Integer number of records removed.
  def self.clean
    Insectdb.peach(Segment.where("type not in ('coding(alt)', 'coding(const)')"), 20) do |s|
        s.delete
    end.length
  end

  # Public: Return the codon at specified location.
  #
  # Returns Codon or nil.
  def self.codon_at( chromosome, position )
    seg = Segment.where("chromosome = ? and start <= ? and stop >= ?",
                         chromosome, position, position).first
    return nil unless seg

    mrna = seg.mrnas.first
    return nil unless mrna

    mrna.codon_at(position)
  end

  # Public: Return all SNPs residing at this segment.
  #
  # Returns ActiveRecord::Relation.
  def snps
    Snp.where("chromosome = ? and position between ? and ?",
               chromosome, start, stop)
  end

  # Public: Return all divs residing at this segment.
  #
  # Returns ActiveRecord::Relation.
  def divs
    Div.where("chromosome = ? and position between ? and ?",
               chromosome, start, stop)
  end

  # Public: Return the strand of mRNA, as part of which this segment gets translated.
  #         It is assumed that strand is the same for all mRNAs of this segment,
  #         so the strand value is derived from any one of them.
  #
  # Returns String with + or -.
  def strand
    (mrna = self.mrnas.first) ? mrna.strand : '+'
  end

  # Public: Return the reference (i.e. of the dm3) sequence for this segment.
  #
  # Returns Insectdb::Sequence object.
  def ref_seq
    if _ref_seq
      _ref_seq
    else
      seq = Reference.ref_seq(chromosome, start, stop, strand)
      update_attributes(:_ref_seq => seq)
      seq
    end
  end

  # Public: return the GC content at the third positions of codons
  #         of this segment.
  #
  # Returns Float.
  def gc
    s = codons.map { |c| c.nuc_codon[2] }.join
    ((s.count('G')+s.count('C')).to_f/codons.count).round(4)
  end

  ##################################
  ######### Private ################
  ##################################

  # Private: Return dn_ds_pn_ps values for this segment.
  #
  # snp_aaf_margin - Set the upper margin for SNP aaf ( ancestral allele
  #                  frequency) value. Default is 100%.
  #
  # Returns Hash.
  def _dn_ds_pn_ps( snp_aaf_margin = 100 )
    s = snps.select { |e| e.aaf < snp_aaf_margin }.map(&:syn?)
    d = divs.map(&:syn?)

    {
      :dn => d.count { |r| r.first == false },
      :ds => d.count { |r| r.first == true  },
      :pn => s.count { |r| r.first == false },
      :ps => s.count { |r| r.first == true  }
    }
  end

  # Private: Inner function used for benchmarking production db.
  #
  # Returns Integer.
  def _pn
    snps.map(&:syn?).count { |r| r.first == false }
  end

end
end
