module Insectdb
class Snp < ActiveRecord::Base
  serialize :alleles, Hash

  validates :chromosome,
            :presence => true,
            :numericality => { :only_integer => true },
            :inclusion => { :in => [0, 1, 2, 3, 4] }

  validates :position,
            :presence => true,
            :numericality => { :only_integer => true }

  validates :sig_count,
            :presence => true,
            :numericality => { :only_integer => true }

  validates :alleles,
            :presence => true

  # Public: Create a new record from an array of nucleotides.
  #
  # col - The Array with nucleotides.
  # chr - The String with chromosome.
  # pos - The Integer with position of nucleotide column.
  #
  # Examples:
  #
  #   Insectdb::Snp.from_col(
  #     ['A','A','A','A','C','C'],
  #     '2R',
  #     87765
  #   )
  #
  # Returns the Insectdb::Snp object.
  def self.from_col( col, chr, pos )
    self.create!(
      :chromosome => Insectdb::CHROMOSOMES[chr],
      :position   => pos,
      :sig_count  => col.select { |n| n != 'N' }.size,
      :alleles    => col.select{ |n| n != 'N'}
                        .inject(Hash.new(0)) { |mem, var| mem[var]+=1; mem })
  end

  # Public: When parsing 163 aligned Drosophila melanogaster sequences column
  #         by column, it is necessary to check each column for being a
  #         polymorphic column.
  #         By definition the column of nucleotides is considered to be
  #         polymorphic if contains more than two types of nucleotide letters.
  #         See the examples for details.
  #
  # col - The Array with nucleotides
  #
  # Examples:
  #
  #   Insectdb::Snp.column_is_polymorphic?(%W[ A A C ]) # => true
  #   Insectdb::Snp.column_is_polymorphic?(%W[ A G C ]) # => true
  #   Insectdb::Snp.column_is_polymorphic?(%W[ A A N ]) # => false
  #   Insectdb::Snp.column_is_polymorphic?(%W[ A A A ]) # => false
  #   Insectdb::Snp.column_is_polymorphic?(%W[ N N N ]) # => false
  #   Insectdb::Snp.column_is_polymorphic?([])          # => false
  #
  # Returns The Boolean.
  def self.column_is_polymorphic?( col )
    col.select{ |n| %W[A C G T].include?(n) }.uniq.size > 1
  end

  def self.set_margin( margin_val )
    ENV["SNP_MARGIN"] = margin_val.to_s
    warn "SNP margin set to #{self.margin}"
  end

  def self.margin
    ENV["SNP_MARGIN"].to_i || 85
  end

  def self.allele_freq_dist_at_poss( chr, poss )
    self.where( "chromosome = ? and position in (?)",
                Insectdb::CHROMOSOMES[chr],
                poss )
        .select('id, dsim, dyak, snp_alleles, dmel_sig_count')
        .group_by{ |r| r.anc_allele_freq.to_i }
        .map { |a| [a[0],a[1].count] }
        .to_hash
  end

  def self.at_poss( chr, poss )
    query =
      self.where(
                  "chromosome = ? and position in (?)",
                   Insectdb::CHROMOSOMES[chr], poss
                )

    poss.map do |pos|
      query.find{ |snp| snp.position == pos }
    end
  end

  # Mind the non_anc_allele_freq_margin!!!
  def self.count_at_poss( chr, poss )
    return 0 if poss.empty?

    # timer = nil
    # warn "\nEntering Snp::count_at_poss for #{chr} with array of #{poss.size} positions"
    # .tap { |a| warn "Positions array sliced into #{a.count} pieces" }
    # .tap { warn "Processing slices"; timer = Time.now }
    # .tap { warn "Took #{(Time.now - timer).round(4)} seconds"}
    poss.each_slice(100000)
        .map do |sli|
          self.where( "chromosome = ? and position in (?)",
                       Insectdb::CHROMOSOMES[chr], sli
                    ).to_a.count{ |snp| snp.anc_allele_freq <= self.margin }
        end
        .reduce(:+)
  end

  # Return alleles of SNPs segregating at given positions.
  #
  # @param [String] strand '+' or '-'
  # @param [String] chr
  # @param [Array] of Integers
  #
  # @return [Array] of Arrays with Strings -> [['A','C'],['G','T']
  def self.alleles_at_poss( strand, chr, poss )
    self.at_poss(chromosome, poss)
        .map{|snp| snp ? snp.freq(strand).map(&:first) : nil }
  end

  # Get allele frequencies.
  #
  # @return [Hash] {'A' => 0.01, 'G' => 0.99 }
  def freq( strand = '+')
    strand == '+' ? _freq : _comp_freq
  end

  # Return the frequency of the next most abundant allele than the passed one.
  #
  # @return [Fixnum]
  def ofreq( allele, strand )
    freq(strand)
      .select{|k| k!=allele}
      .sort_by{|a| a[1]}[-1][1]
  end

  def anc_allele_freq
    ((self.freq[self.anc_allele].to_f)/self.dmel_sig_count)*100
  end

  def non_anc_allele_freq
    100-self.anc_allele_freq
  end

  # Get allele frequencies with complimentary nucleotides.
  #
  # @return [Hash] {'T' => 0.01, 'C' => 0.99 }
  def _comp_freq
    _freq.map{|f| f[0] = Contig.complement(f[0]);f}.to_hash
  end

end
end
