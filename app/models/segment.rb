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
      Insectdb::Segment
        .send(scope)
        .where(:chromosome => '2L')
        .map { |s| s.poss(syn) }
        .flatten

    all_nuc_counts = %W[ A C G T ].map do |nuc|
      Insectdb.mapp(bind) do |bind_bin|
        Insectdb::Reference.count_nucs_at_poss('2L', bind_bin, nuc)
      end
    end

    div_nuc_counts =
      %W[ A C G T ].permutation(2).map do |nucs|
        Insectdb.mapp(bind) do |bind_bin|
          Insectdb::Div.count_at_poss_with_nucs('2L', bind_bin, nucs[1], nucs[0])
        end
      end

    result =
      div_nuc_counts
        .each_slice(3)
        .map(&:inn_sum)
        .map.with_index { |a,i| a.divide_by(all_nuc_counts[i]) }

    [result, div_nuc_counts, all_nuc_counts]
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

  def self.pd( c, query )
    timer = nil

    syn_pos =
      query.where(:chromosome => c)
           .tap { |q| warn "\nEntering Segment::pd for #{c} and query of #{q.count} elements"}
           .tap { warn "Extracting syn positions..."; timer = Time.now}
           .map { |s| s.poss('syn') }
           .flatten
           .tap { warn "Took #{(Time.now - timer).round(4)} seconds"}

    nsyn_pos =
      query.where(:chromosome => c)
           .tap { warn "Extracting nonsyn positions..."; timer = Time.now}
           .map { |s| s.poss('nonsyn') }
           .flatten
           .tap { warn "Took #{(Time.now - timer).round(4)} seconds"}

    ds = Div.count_at_poss(c, syn_pos)
    dn = Div.count_at_poss(c, nsyn_pos)
    ps = Snp.count_at_poss(c, syn_pos)
    pn = Snp.count_at_poss(c, nsyn_pos)

    [[syn_pos, nsyn_pos], ds, dn, ps, pn]
  end

  # Execute MacDonald-Kreitman test for segments returned by query
  def self.mk( query, exon_shift, snp_margin )
    Insectdb.reconnect
    Insectdb::Segment.clear_cache
    Insectdb::Segment.set_shifts(exon_shift, 0)
    Insectdb::Snp.set_margin(snp_margin)
    Insectdb.reconnect

    # raw =
    #   Insectdb.mapp(%W[2L 2R 3L 3R X]) { |c| self.pd(c, query) }
    #   .reduce() { |p,n| p.map.with_index { |v,i| v+n[i] } }
    raw =
      %W[2L 2R 3L 3R X].map { |c| self.pd(c, query) }
                       .reduce { |p,n| p.map.with_index { |v,i| v+n[i] } }

    length_sum = query.map(&:length).reduce(:+)

    poss_counts =
      raw[0].each_slice(2)
            .reduce{|s,n| [s[0]+n[0],s[1]+n[1]]}
            .map(&:count)

    norm = poss_counts.reduce(:+).to_f

    ds_norm = raw[1]/norm
    dn_norm = raw[2]/norm
    ps_norm = raw[3]/norm
    pn_norm = raw[4]/norm

    ds_per_syn_poss    = (raw[1]/poss_counts[0].to_f)*100
    dn_per_nonsyn_poss = (raw[2]/poss_counts[1].to_f)*100
    ps_per_syn_poss    = (raw[3]/poss_counts[0].to_f)*100
    pn_per_nonsyn_poss = (raw[4]/poss_counts[1].to_f)*100

    alpha = 1-((ds_norm*pn_norm)/(dn_norm*ps_norm))

    {
      :alphaNorm => alpha.round(4),
      :dsNorm => ds_norm.round(4),
      :dnNorm => dn_norm.round(4),
      :psNorm => ps_norm.round(4),
      :pnNorm => pn_norm.round(4),
      :ds => raw[1],
      :dn => raw[2],
      :ps => raw[3],
      :pn => raw[4],
      :dsPerCent => ds_per_syn_poss.round(4),
      :dnPerCent => dn_per_nonsyn_poss.round(4),
      :psPerCent => ps_per_syn_poss.round(4),
      :pnPerCent => pn_per_nonsyn_poss.round(4),
      :synPoss => poss_counts[0].to_i,
      :nonsynPoss => poss_counts[1].to_i,
      :possSum => norm.to_i,
      :lengthSum => length_sum.to_i
    }
  end

  def self.mk_formatted( query, exon_shift )
    mk100 = self.mk(query, exon_shift, 100)
    mk85  = self.mk(query, exon_shift, 85)
    puts "%tr"
    puts "\s\s%td\n\s\s#{mk100[:alphaNorm]}&emsp;#{mk85[:alphaNorm]}"
    puts "\s\s%td\n\s\s#{mk100[:dnNorm]}"
    puts "\s\s%td\n\s\s#{mk100[:dsNorm]}"
    puts "\s\s%td\n\s\s#{mk100[:pnNorm]}&emsp;#{mk85[:pnNorm]}"
    puts "\s\s%td\n\s\s#{mk100[:psNorm]}&emsp;#{mk85[:psNorm]}"
    puts "%tr"
    puts "\s\s%td\n\s\s#{mk100[:dn]}"
    puts "\s\s%td\n\s\s#{mk100[:dnPerCent]}"
    puts "\s\s%td\n\s\s#{mk100[:ds]}"
    puts "\s\s%td\n\s\s#{mk100[:dsPerCent]}"
    puts "\s\s%td\n\s\s#{mk100[:pn]}"
    puts "\s\s%td\n\s\s#{mk100[:pnPerCent]}"
    puts "\s\s%td\n\s\s#{ mk85[:pn]}"
    puts "\s\s%td\n\s\s#{ mk85[:pnPerCent]}"
    puts "\s\s%td\n\s\s#{mk100[:ps]}"
    puts "\s\s%td\n\s\s#{mk100[:psPerCent]}"
    puts "\s\s%td\n\s\s#{ mk85[:ps]}"
    puts "\s\s%td\n\s\s#{ mk85[:psPerCent]}"
    puts "\s\s%td\n\s\s#{mk100[:synPoss]}"
    puts "\s\s%td\n\s\s#{mk100[:nonsynPoss]}"
    puts "\s\s%td\n\s\s#{mk100[:lengthSum]}"
    puts "\s\s%td\n\s\s#{Insectdb::Segment.exon_shift.to_s}"
    puts "\s\s%td\n\s\s#{Insectdb::Snp.margin.to_s}"
  end

  def self.stats_for_query( query )
    syn = query.map{|s| s.poss('syn').count}.reduce(:+)
    nonsyn = query.map{|s| s.poss('nonsyn').count}.reduce(:+)

    smry =
      Insectdb.mapp(%W[2L 2R 3L 3R X]) { |c| self.pd(c, query) }
              .reduce() { |p,n| p.map.with_index { |v,i| v+n[i] } }
    d = [syn,nonsyn] + smry[1..(-1)]

    puts "%tr"
    d.each { |v| puts "\s\s%td\n\s\s\s\s#{v}" }
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
