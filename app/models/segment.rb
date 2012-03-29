module Insectdb
class Segment < ActiveRecord::Base
  self.inheritance_column = 'inheritance_type'
  has_and_belongs_to_many :mrnas

  EXON_SHIFT = 5
  INTRON_SHIFT = 30

  scope :introns, where(:type => 'intron')
  scope :alt, where(:type => 'coding(alt)')
  scope :const, where(:type => 'coding(const)')

  def codons
    mrnas.first
         .codons_btwn(start+shift, stop-shift)
  end

  # Return the size of the shift from both ends of the segment.
  #
  # @return [Fixnum] shift size in bp
  def shift
    type == 'intron' ? INTRON_SHIFT : EXON_SHIFT
  end

  # Is this an alternatively spliced exon of cassette type?
  #
  # @return [Boolean]
  def cassette?
    left  = Insectdb::Segment.where(:stop  => start-1).first
    right = Insectdb::Segment.where(:start => stop+1).first

    if (!left.nil? && left.splicing != 'intron') ||
       (!right.nil? && right.splicing != 'intron')
      true
    else
      false
    end
  end

  def syn_freqs
    mrnas.first
         .codons_with_coords_btwn(start+shift, stop-shift)
         .map{|codon| Insectdb::Codon.syn_coords_in(codon) }
         .flatten
         .map{|pos| (snp=snp_at(pos)).empty? ? nil : snp.first.freq(strand)[ref_seq[pos]]}
         .compact
         .map{|freq| (1-freq).round(3)}
  end

  def non_syn_freqs
    mrnas.first
         .codons_with_coords_btwn(start+shift, stop-shift)
         .map{|codon| Insectdb::Codon.nonsyn_coords_in(codon) }
         .flatten
         .map{|pos| (snp=snp_at(pos)).empty? ? nil : snp.first.freq(strand)[ref_seq[pos]]}
         .compact
         .map{|freq| (1-freq).round(3)}
  end

  # Count the number of sites (in this segment) mutations at which
  # always cause amino-acid change.
  #
  # @return [Fixnum]
  def count_syn_sites
    codons.map{|codon| Insectdb::Codon.count_syn_sites(codon) }
          .inject(:+)
  end

  # Count the number of sites (in this segment) mutations at which
  # never cause amino-acid change.
  #
  # @return [Fixnum]
  def count_nonsyn_sites
    codons.map{|codon| Insectdb::Codon.count_nonsyn_sites(codon) }
          .inject(:+)
  end


  # @param [String] types 'dmel_dsim' or 'dmel_dyak' or 'dsim_dyak'
  # @return [ActiveRecord::Relation]
  def divs( types )
    Insectdb::Reference
      .where("chromosome = ? and position between ? and ? and #{types} = false",
              chromosome, start, stop)
  end

  # Return the strand of mRNA, as part of which this segment gets tranlated.
  # It is assumed that strand is the same for all mRNAs of this segment,
  # so the strand value is derived from any one of them.
  #
  # @return [String] '+' or '-'
  def strand
    self.mrnas.first.strand
  end

  # Return a reference sequence wrapped in Contig object.
  # Whereas Contig object has knowledge about sequence location and strand.
  #
  # @return [Insectdb::Contig]
  def ref_seq
    @ref_seq ||= Insectdb::Contig.new(__ref_seq, start, strand )
  end

  # Get SNPs occurring at positions of this segment.
  # If SNP happens to be at 'N' position of reference sequence -
  # it is not included in the resulting array.
  #
  # @return [ActiveRecord::Relation]
  def snps
    Insectdb::Snp
      .where("chromosome = ? and position between ? and ?",
              chromosome, start, stop)
  end

  # Search for SNP at a particular position.
  #
  # @return [ActiveRecord::Relation]
  def snp_at( pos )
    Insectdb::Snp
      .where("chromosome = ? and position = ? ",
              chromosome, pos)
  end

  # Get reference nucleotide sequence for this segment.
  # The nucleotide at each position is considered referential if it is the
  # same in D.simulans and D.yakuba
  #
  # @return [String] 'ACGTNNNTT'
  def __ref_seq
    Insectdb::Reference
      .where("chromosome = ? and position between ? and ?",
              self.chromosome, self.start, self.stop)
      .order("position")
      .select('position, dsim, dsim_dyak')
      .map{|r| r['dsim_dyak'] ? r['dsim'] : 'N'}
      .join
  end

  # Seed initial data from seed file.
  #
  # @param [String] path "./db/seed/reference/segments"
  def self.seed( path )
    File.open(File.join(path,'segments'),'r') do |f|
      f.lines.each do |l|
        l = l.chomp.split
        seg = self.new do |seg|
          seg.id = l[0]
          seg.chromosome = l[1]
          seg.start = l[2]
          seg.stop = l[3]
          seg.type = l[4]
          seg.save
        end
      end
    end
  end

end
end
