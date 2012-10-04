module Insectdb
module Seed

  def self.reference_enums_for( chr, path )
    [
      "drosophila_melanogaster/dm3_#{chr}.fa.gz",
      "drosophila_simulans/droSim1_#{chr}.fa.gz",
      "drosophila_yakuba/droYak2_#{chr}.fa.gz"
    ].map{ |f| Insectdb::SeqEnum.new(File.join(path, f)) }
      .zip([:dmel,:dsim,:dyak])
      .map(&:reverse)
      .to_hash
  end

  # TODO: Begin here!!! yesterday finished here on implementing Snp::from_col
  def self.seq_processor( ref, dmel_col, chr, pos )
    if dmel_col.select{ |n| %W[A C G T].include?(n) }.uniq.size > 1
      Insectdb::Snp.from_col(dmel_col, chr, pos)
    elsif (ref[:dsim] == ref[:dyak]) && (ref[:dmel] != ref[:dsim])
      Insectdb::Div.from_hash(ref, chr, pos)
    end
    Insectdb::Reference.from_hash(ref, chr, pos)
  end

  # Seed Reference, Snp and Div tables for one chromosome
  def self.ref_div_snp( chr, path )
    ref_enums = reference_enums_for(chr, path)

    dmel_enums =
      Dir[File.join(path, "drosophila_melanogaster/*_#{chr}.fa.gz")]
        .map{|f| Insectdb::SeqEnum.new(f) }

    step = 200000
    map = (0..(ref_enums[:dmel].length/step)).map{ |v| v*step }
    Parallel.each(map, :in_processes => 30) do |ind|
      ActiveRecord::Base.connection.reconnect!

      dmel_en = ref_enums[:dmel][ind, step]
      dsim_en = ref_enums[:dsim][ind, step]
      dyak_en = ref_enums[:dyak][ind, step]
      snps = dmel_enums.map{|e| e[ind, step]}

      step.times do |i|
        dmel = dmel_en.next
        dsim = dsim_en.next
        dyak = dyak_en.next
        snp_raw  = snps.map(&:next).select{|n| %W[A C G T].include?(n)}
        snp_boo = (snp_raw.uniq.size > 1)
        doc = {
          :position       => (ind+i)+1,
          :chromosome     => CHROMOSOMES[chr],
          :dmel           => dmel,
          :dsim           => dsim,
          :dyak           => dyak,
          :dmel_dsim      => self.na_eq?(dmel,dsim),
          :dmel_dyak      => self.na_eq?(dmel,dyak),
          :dsim_dyak      => self.na_eq?(dsim,dyak),
          :dmel_sig_count => snp_raw.count,
          :snp            => snp_boo,
          :snp_alleles    => (snp_boo ? JSON.dump(snp_raw.reduce(Hash.new(0)){|h,a| h[a]+=1;h}) : nil)
        }
        self.create!(doc)
      end
    end
  end
end
end
