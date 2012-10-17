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

    raw =
      %W[2L 2R 3L 3R X].map { |c| self.pd(c, query) }
                       .reduce { |p,n| p.map.with_index { |v,i| v+n[i] } }

    length_sum = query.map(&:length).reduce(:+)

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

  ########################################
  ############ Binding stuff #############
  ########################################


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

end
end
