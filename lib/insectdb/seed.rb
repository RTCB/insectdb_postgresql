module Insectdb
module Seed

  def self.run
    s = lambda do |*args|
      time = Time.now
      Insectdb::Seed.send(args[0],
                          Insectdb::Config::PATHS[args[0]],
                          *args[1..(-1)])
      (Time.now - time).round
    end

    puts "Seeding Reference, Div and Snp"
    Insectdb::CHROMOSOMES.keys.each do |chr|
      printf "--for chromosome #{chr} "
      time = s.call(:seqs, chr)
      puts "took #{time} sec"
    end

    puts "*-----*"
    printf "Seeding Segments "
    puts "took #{s.call(:segments)} sec"

    puts "*-----*"
    printf "Seeding Mrnas "
    puts "took #{s.call(:mrnas)} sec"

    puts "*-----*"
    printf "Seeding Genes "
    puts "took #{s.call(:genes)} sec"
  end

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

  # TODO Write docs
  # Public: The general purpose of this function is to
  def self.seq_processor( ref, dmel_col, chr, pos )
    check = [
              Snp.column_is_polymorphic?(dmel_col),
              Div.position_is_divergent?(ref)
            ]

    case check
    when [true, true], [false, false] then nil
    when [true, false] then Snp.from_col(dmel_col, chr, pos)
    when [false, true] then Insectdb::Div.from_hash(chr, pos)
    end

    Insectdb::Reference.from_hash(ref, chr, pos)
  end

  # Seed Reference, Snp and Div tables for one chromosome
  def self.seqs( path, chr )
    ref_enums = reference_enums_for(chr, path)

    snp_enums =
      Dir[File.join(path, "drosophila_melanogaster/*_#{chr}.fa.gz")]
        .map{|f| Insectdb::SeqEnum.new(f) }

    step = (ENV['ENV'] == 'test' ? 5 : 200000)
    map = (0..(ref_enums[:dmel].length/step)).map{ |v| v * step }

    Parallel.each(map, :in_processes => (ENV['ENV'] == 'test' ? 0 : 8)) do |ind|
      ActiveRecord::Base.connection.reconnect!

      dmel_en = ref_enums[:dmel][ind, step]
      dsim_en = ref_enums[:dsim][ind, step]
      dyak_en = ref_enums[:dyak][ind, step]
      snp_en  = snp_enums.map{ |e| e[ind, step] }

      step.times do |i|
        self.seq_processor(
          {
            :dmel => dmel_en.next,
            :dsim => dsim_en.next,
            :dyak => dyak_en.next
          },
          snp_en.map(&:next),
          chr,
          ind+i+1
        )
      end
    end
  end

  def self.segments( path )
    File.open(File.join(path), 'r') do |f|
      Insectdb.peach(f.lines.to_a, 16) do |l|
        l = l.chomp.split
        Insectdb::Segment.create!(
          :id         => l[0],
          :chromosome => Insectdb::CHROMOSOMES[l[1]],
          :start      => (l[2].to_i - 1),
          :stop       => (l[3].to_i - 1),
          :type       => l[4],
          :length     => (l[3].to_i - 1)-(l[2].to_i - 1)
        )
      end
    end
    puts 'Segments table successfully uploaded'
  end

  def self.mrnas( path )
    File.open(File.join(path),'r') do |f|
      f.lines.each do |l|
        l = l.chomp.split
        Insectdb::Mrna.create!(
          :id         => l[0],
          :chromosome => Insectdb::CHROMOSOMES[l[1]],
          :strand     => l[2],
          :start      => l[3],
          :stop       => l[4]
        )
      end
    end
  end

  def self.genes( path )
    File.open(File.join(path),'r') do |f|
      f.lines.each do |l|
        l = l.chomp.split
        Insectdb::Gene.create!(
          :id          => l[0],
          'flybase_id' => l[1]
        )
      end
    end
  end

  def self.mrnas_segments( path )
    File.open(File.join(path,'mrnas_segments'),'r') do |f|
      f.lines.each do |l|
        l = l.chomp.split
        Insectdb::MrnasSegments.create!(
          'mrna_id'    => l[0].to_i,
          'segment_id' => l[1].to_i
        )
      end
    end
  end

  def self.genes_mrnas( path )
    File.open(File.join(path,'genes_mrnas'),'r') do |f|
      f.lines.each do |l|
        l = l.chomp.split
        Insectdb::MrnasSegments.create!(
          'mrna_id' => l[0].to_i,
          'gene_id' => l[1].to_i
        )
      end
    end
  end

end
end
