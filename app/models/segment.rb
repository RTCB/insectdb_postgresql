module Insectdb
class Segment < ActiveRecord::Base
  serialize :supp, Hash
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


  # This vars should be set in the environment
  # EXON_SHIFT = 0
  # INTRON_SHIFT = 30

  # Public: Clear all fields like _* in table.
  #
  # Returns true, always =).
  def self.clear_cache
    ActiveRecord::Base.connection.execute("
      UPDATE segments SET
      _codons=NULL,
      _syn_poss=NULL,
      _nonsyn_poss=NULL,
      _ref_seq=NULL
    ")
    warn "Cache fields successfully cleared in table Segments"
  end

  def self.set_shifts( exon_shift, intron_shift )
    ENV['INTRON_SHIFT'] = intron_shift.to_s
    ENV['EXON_SHIFT']   = exon_shift.to_s
    warn "Exon shift set to: #{self.exon_shift}"
    warn "Intron shift set to: #{self.intron_shift}"
  end

  def self.exon_shift
    ENV['EXON_SHIFT'].to_i || 0
  end

  def self.intron_shift
    ENV['INTRON_SHIFT'].to_i || 0
  end

  # Public: Set bind_mean field for all coding segments.
  #
  # The value is counted only for position that happen to be 'A' or 'T'
  #
  # Returns: True or message "Looks like finished"
  def self.seed_bind_mean( path )
    segs = Insectdb::Segment
             .coding
             .where(:chromosome => '2L')
             .order(:start)

    ends = segs.map{|s| [s.start, s.stop]}

    bind =
      File.open(path)
        .lines
        .map{|li| l=li.chomp.split(","); l[0]=l[0].to_i; l[1]=l[1].to_f; l }
        .sort_by(&:first)
        .each

    prev_el = nil
    pos_hold = []

    ends.each_with_index do |iends, ind|
      el = prev_el || bind.next
      if el.first < iends.first
        prev_el = nil
        redo
      elsif (el.first >= iends.first) && (el.first <= iends.last)
        pos_hold << el
        prev_el = nil
        redo
      else
        prev_el = el
        next if pos_hold.empty?
        pos_hold = pos_hold.select{ |b| %W[A T].include?(segs[ind].ref_seq[b.first]) }
        segs[ind].update_attributes('bind_mean' => pos_hold.map(&:last).mean)
        pos_hold = []
      end
    end

    true
  rescue StopIteration
    warn 'Looks like finished'
  end


  # Set cassette field for each alternatively spliced segment.
  #
  # @return [Boolean]
  def self.set_cassette
    self.alt.each do |s|
      left  = self.where("chromosome = ? and stop = ?", s.chromosome, s.start-1).first
      right = self.where("chromosome = ? and start = ?", s.chromosome, s.stop+1).first
      s.update_attributes(:cassette => (left.nil? or right.nil?) ? true : false)
    end
  end

  # Public: Return all codons for segment as strings of size 3.
  #
  # Examples
  #
  #   codons
  #   # => ['ATG','CCG','TAC','CCC' ]
  #
  # Returns an Array with Strings of size 3.
  def codons
    if _codons.nil?
      update_attributes(
        "_codons" => Marshal.dump(
            mrnas.first.codons_btwn(start+shift, stop-shift).select{|c| !c.include?('N')}
      ).force_encoding('UTF-8'))
    end
    Marshal.load(_codons)
  end

  # Return the size of the shift from both ends of the segment.
  #
  # @return [Fixnum] shift size in bp
  def shift
    type == 'intron' ? Insectdb::Segment.intron_shift : Insectdb::Segment.exon_shift
  end

  # Return all syn or nonsyn positions in this segment
  #
  # @param [String] syn 'syn' or 'nonsyn'
  def poss( syn )
    case syn
    when 'all'
      case type
      when 'intron'
        (start..stop).to_a[7,30]
      else
        (start..stop).to_a[4..(length-6)]
      end
    else
      f = "_#{syn}_poss"
      if self.send(f).nil?
        update_attributes(
          f => JSON.dump(
            codons.map{ |c| c.poss(syn) }
                  .flatten
        ))
      end
      JSON.parse(self.send(f))
    end
  end

  # Return the strand of mRNA, as part of which this segment gets translated.
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
    if _ref_seq.nil?
      update_attributes(
        "_ref_seq" => Reference.seq_for(chromosome, start, stop))
    end
    Insectdb::Contig.new(_ref_seq, start, (type == 'intron' ? '+' : strand) )
  rescue
    warn self.inspect
  end

  # Public: return the GC content at the third positions of codons of this segment.
  def gc
    s = codons.map { |c| c.nuc_codon[2] }.join
    ((s.count('G')+s.count('C')).to_f/codons.count).round(4)
  end

end
end
