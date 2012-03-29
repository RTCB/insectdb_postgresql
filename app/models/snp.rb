module Insectdb
class Snp < ActiveRecord::Base

  CHROMOSOMES = {1 => '2R',
                 2 => '2L',
                 3 => '3R',
                 4 => '3L',
                 5 => 'X'}

  # Get allele frequencies.
  #
  # @return [Hash] {'A' => 0.01, 'G' => 0.99 }
  def freq( strand = '+')
    strand == '+' ? __freq : __comp_freq
  end

  # Get allele frequencies with complimentary nucleotides.
  #
  # @return [Hash] {'T' => 0.01, 'C' => 0.99 }
  def __comp_freq
    __freq.map{|f| f[0] = Contig.complement(f[0]);f}.to_hash
  end

  # Parse JSON data in 'frequencies' field.
  #
  # @return [Hash]
  def __freq
    JSON.parse(frequencies).map{|a| a[1] = a[1];a}.to_hash
  end

  def self.seed( path )
    Parallel.each(self::CHROMOSOMES.values,
                  :in_processes => 3) do |chr|

      enums =
        Dir[File.join(path, "drosophila_melanogaster/*_#{chr}.fa.gz")]
          .sort_by{|n| n[0]}
          .map{|f| Insectdb::SeqEnum.new f }

      enums.last.length.times do |ind|
        self.from_nuc_set(ind+1, chr, enums.map(&:next))
      end

    end
  end
  # Compute SNP characteristics
  #
  # Method returns a hash with three keys:
  #
  # * alleles [Array] has the nucleotides that form polymorphism in
  #   passed nucleotide set
  # * abundance [Fixnum] percent of the most abundant allele in the set passed,
  #   see {SpliceEvo.ratio_for_nuc_seq}
  # * amount [Fixnum] total number of valid nucleotide letters in passed set
  #
  # @note
  #   SNPs can be tri-allelic and four-allelic.
  #
  # @param [Array] passed_nuc_seq an array of nucleotides
  # @return [Hash]
  def self.from_nuc_set(pos, chromosome, nuc_set )
    nuc_set.delete('N')

    return nil unless (nuc_set.size >= 150 && nuc_set.uniq.size > 1)

    frequencies = self.compute_frequencies(nuc_set)
    abundance = frequencies.to_a[-1][-1]*100

    self.create!(
      {
        'position'    => pos,
        'chromosome'  => chromosome,
        'abundance'   => abundance.to_i,
        'frequencies' => frequencies.to_json,
        'amount'      => nuc_set.size,
      }
    )

  end

  # Compute allele frequencies
  #
  # @param [Array] passed_nuc_set
  # @return [Hash]
  def self.compute_frequencies( nuc_set )
    nuc_set.inject(Hash.new(0)){|s,v| s[v]+=1;s }
           .to_a
           .sort{|a,b| a[1]<=>b[1] }
           .map{|a| a[1] /= nuc_set.size.to_f; a }
           .to_hash
  end

end
end
