module Insectdb
module Routines

  def self.per_segment_summary
    Insectdb::Snp.set_margin(85)
    Insectdb.mapp(Insectdb::Segment.coding, 10) do |s|
      {
        'segment_id' => s.id,
        'chromosome' => s.chromosome,
        'strand' => s.strand,
        'start' => s.start,
        'stop' => s.stop,
        'dn' => Insectdb::Div.count_at_poss(s.chromosome, s.poss('nonsyn')),
        'ds' => Insectdb::Div.count_at_poss(s.chromosome, s.poss('syn')),
        'pn' => Insectdb::Snp.count_at_poss(s.chromosome, s.poss('nonsyn')),
        'ps' => Insectdb::Snp.count_at_poss(s.chromosome, s.poss('syn'))
      }
    end
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

  # Public: Generate a report for a set of segments
  #
  # query - The Enumerable with segments to be processed
  def self.summary_formatted( query, exon_shift )
    # Insectdb.reconnect
    # Insectdb::Segment.clear_cache
    Insectdb::Segment.set_shifts(exon_shift, 0)

    site_count =
      %W[syn nonsyn].map do |syn|
        %W[2L 2R 3L 3R X].map do |chr|
          query.where(:chromosome => chr)
               .map { |s| s.poss(syn).count }
               .reduce(:+)
        end.reduce(:+)
      end

    poly_data =
      Insectdb.mapp(%W[syn nonsyn]) do |syn|
        Insectdb.mapp(%W[2L 2R 3L 3R X]) do |chr|
          Insectdb::Snp.allele_freq_dist_at_poss(chr, query.map { |s| s.poss(syn) }.flatten)
        end.reduce{ |s,n| s.merge(n){ |key, a, b| a+b } }
      end

    div_data =
      Insectdb.mapp(%W[syn nonsyn]) do |syn|
        Insectdb.mapp(%W[2L 2R 3L 3R X]) do |chr|
          Insectdb::Div.count_at_poss(chr, query.map { |s| s.poss(syn) }.flatten)
        end.reduce(:+)
      end

    poly_data_formatted  =
      poly_data.reduce{|s,n| s.merge(n){|k,a,b| [a,b]}}
               .sort_by(&:first)
               .map { |v| v.last.join("\t") }
               .join("\n")
    div_data_formatted   = div_data.join("\t")
    site_count_formatted = site_count.join("\t")

    poly_data_formatted + "\n" +
    div_data_formatted  + "\n" +
    site_count_formatted
  end

  def self.mk_formatted( query, exon_shift )
    mk100 = self.mk(query, exon_shift, 100)
    mk85  = self.mk(query, exon_shift, 85)
    puts "%tr"
    puts "\s\s%td\n\s\s#{mk100[:alphaNorm]}"
    puts "\s\s%td\n\s\s#{mk85[:alphaNorm]}"
    puts "\s\s%td\n\s\s#{mk100[:dnNorm]}"
    puts "\s\s%td\n\s\s#{mk100[:dsNorm]}"
    puts "\s\s%td\n\s\s#{mk100[:pnNorm]}"
    puts "\s\s%td\n\s\s#{mk85[:pnNorm]}"
    puts "\s\s%td\n\s\s#{mk100[:psNorm]}"
    puts "\s\s%td\n\s\s#{mk85[:psNorm]}"
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
    # puts "\s\s%td\n\s\s#{mk100[:lengthSum]}"
    # puts "\s\s%td\n\s\s#{Insectdb::Segment.exon_shift.to_s}"
    # puts "\s\s%td\n\s\s#{Insectdb::Snp.margin.to_s}"
  end

  # Execute MacDonald-Kreitman test for segments returned by query
  def self.mk( query, exon_shift, snp_margin )
    Insectdb.reconnect
    Insectdb::Segment.clear_cache
    Insectdb::Segment.set_shifts(exon_shift, 0)
    Insectdb::Snp.set_margin(snp_margin)

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

end
end
