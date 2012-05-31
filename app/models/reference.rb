module Insectdb
class Reference < ActiveRecord::Base
  self.table_name = 'reference'

  CHROMOSOMES = {'2R' => 0,
                 '2L' => 1,
                 '3R' => 2,
                 '3L' => 3,
                 'X'  => 4}

  def self.seed_binding( path )
    binding =
      File.open(path)
        .lines
        .map{|li| l=li.chomp.split(","); l[0]=l[0].to_i; l[1]=l[1].to_f; l }
        .sort_by(&:first)
        .each

    poss = Insectdb::Segment.coding.map { |s| s.poss('all') }.flatten.compact.sort.each

    b_prev = nil
    p_prev = nil
    result = []

    loop do
      p = p_prev || poss.next
      b = b_prev || binding.next

      if p < b.first
        b_prev = b
        p_prev = nil
        next
      elsif p == b.first
        result << b
        p_prev = nil
        b_prev = nil
      else
        b_prev = nil
        p_prev = p
        next
      end
    end

    warn "#{result.size}"
    binding = nil
    poss = nil
    GC.start

    warn 'Isect complete!'

    bind_sl = result.each_slice(10000)

    Insectdb.peach(((1..(bind_sl.count)).to_a), 5) do |ind|
      bind_sl.next.each do |b|
        Insectdb::Reference
          .where(:chromosome => '1')
          .where(:position => (b.first-1))
          .first
          .update_attributes(:binding => b.last)
      end
    end
  end

  def self.pl_seed( path )
    CHROMOSOMES.keys.each{|chr| self.parallel_seed(path, chr)}
  end

  def self.count_nucs_at_poss( chr, poss, nuc )
    poss.each_slice(1000).map do |p|
      self.where("chromosome = ? and
                  position in (?) and
                  dsim_dyak = true and
                  dsim = ?", CHROMOSOMES[chr], poss, nuc)
          .count
    end.reduce(:+)
  end

  def self.parallel_seed( path, chr )
    ref_enums =
      [
        "drosophila_melanogaster/dm3_#{chr}.fa.gz",
        "drosophila_simulans/droSim1_#{chr}.fa.gz",
        "drosophila_yakuba/droYak2_#{chr}.fa.gz"
      ].map{|f| Insectdb::SeqEnum.new(File.join(path, f)) }
        .zip([:dmel,:dsim,:dyak])
        .map(&:reverse)
        .to_hash

    dmel_enums =
      Dir[File.join(path, "drosophila_melanogaster/*_#{chr}.fa.gz")]
        .map{|f| Insectdb::SeqEnum.new(f) }

    step = 200000
    map = (0..(ref_enums[:dmel].length/step)).map{|v| v*step}
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

  # Returns: A String
  def self.seq_for( chromosome, start, stop )
    self
      .where("chromosome = ? and position between ? and ?",
              CHROMOSOMES[chromosome], start, stop)
      .order("position")
      .map{|r| (r['dsim_dyak'] && r['dmel_sig_count'] >= 150) ? r['dsim'] : 'N'}
      .join
  end

  def self.na_eq?( char_1, char_2 )
    (%W[A C G T].include?(char_1)) &&
    (%W[A C G T].include?(char_2)) &&
    (char_1 == char_2)
  end

end
end
