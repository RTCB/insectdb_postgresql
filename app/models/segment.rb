module Insectdb
class Segment < ActiveRecord::Base

  self.inheritance_column = 'inheritance_type'

  has_and_belongs_to_many :mrnas

  scope :int, where(:type => 'intron')
  scope :sh_int, where("type = 'intron' and length between 50 and 80")
  scope :alt, where(:type => 'coding(alt)')
  scope :const, where(:type => 'coding(const)')
  scope :coding, where("type != 'intron'")
  scope :cass, where(:cassette => true)
  scope :noncass, where(:cassette => false)

  EXON_SHIFT = 5
  INTRON_SHIFT = 30

  # Public: Clear all fields like _* in table.
  #
  # Returns true, always =).
  def self.clear_cache
    self.all.each do |s|
      s.update_attributes(
        "_codons" => nil,
        "_syn_poss" => nil,
        "_nonsyn_poss" => nil,
        "_ref_seq" => nil
      )
    end
    true
  end

  def self.divs_per_bin_for( syn, query )
    data = Insectdb.bind('insectdb/data/dm3_basepairs_2L_out')
    syn_poss = query.map { |s| s.poss(syn) }.flatten
    warn "Data loading complete"

    data.map do |poss|
      iposs = poss.isect(syn_poss)
      val = iposs.each_slice(10000)
                 .map { |s| Insectdb::Div.count_at_poss('2L', s) }
                 .sum
      iposs.count == 0 ? 0 : (val.to_f/iposs.count)
    end
  end

  def self.draw_counts_for( syn, query )
    data = Insectdb.bind('insectdb/data/dm3_basepairs_2L_out')
    syn_poss = query.map { |s| s.poss(syn) }.flatten

    res = data.map { |poss| poss.isect(syn_poss).count }
    res.map { |v| v.to_f/res.sum }
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

  # Seed initial data from seed file.
  #
  # @param [String] path "./db/seed/reference/"
  def self.seed( path )
    File.open(File.join(path,'segments'),'r') do |f|
      Insectdb.peach(f.lines.to_a, 16) do |l|
        l = l.chomp.split
        seg = Segment.new do |seg|
          seg.id = l[0]
          seg.chromosome = l[1]
          seg.start = l[2].to_i-1
          seg.stop = l[3].to_i-1
          seg.type = l[4]
          seg.length = seg.stop - seg.start
          seg.save
        end
      end
    end
    true
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

  # Public: Count divergencies occuring at synonymous or
  # nonsynonymous positions in all segments passed.
  #
  # syn - The String with 'syn' or 'nonsyn'.
  # query - The Enumerable with all segments to be processed.
  #
  # Returns an Array with:
  # - the total number of synonymous/nonsynonymous positions on this segments as Integer
  # - the total number of divs occurring at the above-mentioned positions as Integer.
  # - the number of divs divided by the number of positions as Float.
  def self.divs_at( syn, query )
    count =
      Insectdb.mapp(query, 8) { |s| [Div.count_at_poss(s.chromosome, s.poss(syn)), s.poss(syn).count] }
              .reduce{ |s,n| s[0]+=s[0]; s[1]+=s[1]; s }

    count + [count[0].to_f/count[1]]
  end

  def self.bind_divs_for_all_nucs( syn, scope )
    bind = Insectdb.bind

    syn_poss =
      Segment.send(scope)
             .where(:chromosome => '2L')
             .map { |s| s.poss(syn) }
             .flatten

    %W[ A C G T ].permutation(2).map do |nucs|
      bind.map do |bind_bin|
        bind_bin.isect(syn_poss).each_slice(5000) do |sl|
          Div.count_at_poss_with_nucs('2L', sl, nucs[0], nucs[1])
        end.reduce(:+)
      end
    end
  end

  def self.divs_with_nucs_for( syn, scope, dmel_nuc, simyak_nuc )
    div_count = Insectdb.mapp(Segment.send(scope), 8) do |s|
      positions = s.poss(syn).select { |p| s.ref_seq[p] == simyak_nuc }
      [Div.count_at_poss_with_nucs(s.chromosome, positions, dmel_nuc, simyak_nuc), positions.count]
    end
    result = div_count.inject { |s,n| s[0]+=n[0]; s[1]+=n[1]; s }
    File.open("insectdb/results/divs_nucs_#{syn}_#{scope}", 'a') do |f|
      f << ["#{dmel_nuc}-#{simyak_nuc}", result[0], result[1], ((result[0].to_f)/result[1])].join("\t")
      f << "\n"
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
    type == 'intron' ? INTRON_SHIFT : EXON_SHIFT
  end

  # Return frequencies of snps segregating at synonymous positions.
  # The non-referential frequencies are returned.
  #
  # @example
  #   freqs_at([1234,1254,1875]) #=> [1, 15, 7, 1]
  #
  # @param [Array] poss an array of Integers
  # @return [Array]
  def snp_freqs_at( poss )
    Snp.at_poss(chromosome, poss)
       .compact
       .map{ |snp| snp.ofreq(ref_seq[snp.position], strand) }
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
