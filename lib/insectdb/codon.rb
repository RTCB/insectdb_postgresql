module Insectdb
class Codon
  attr_reader :nuc_codon, :mut_codon, :count

  # If a site mutation in codon always results in
  # amino-acid change then site is marked as 'n'.
  # If a site mutation in codon never results in
  # amino-acid change then site is marked as 's'.
  # If a site mutation in codon sometimes changes
  # the amino-acid and sometimes not then site is marked as 'u'.
  SITE_SYNONYMITY = {
    'GCC' => 'nns',
    'AGT' => 'nnu',
    'TGA' => 'uuu',
    'TGT' => 'nnu',
    'CGA' => 'uns',
    'ATC' => 'nnu',
    'AAC' => 'nnu',
    'AGC' => 'nnu',
    'TAC' => 'nnu',
    'ACA' => 'nns',
    'TCG' => 'nns',
    'CCG' => 'nns',
    'CTG' => 'uns',
    'GCA' => 'nns',
    'GTG' => 'uns',
    'AAG' => 'nnu',
    'GTT' => 'nns',
    'CAC' => 'nnu',
    'AGA' => 'unu',
    'ACC' => 'nns',
    'CCA' => 'nns',
    'TGG' => 'unu',
    'CGC' => 'nns',
    'CTC' => 'nns',
    'TTG' => 'unu',
    'TAA' => 'nuu',
    'CAG' => 'nnu',
    'ACG' => 'nns',
    'ATG' => 'unu',
    'AAA' => 'nnu',
    'GTA' => 'uns',
    'CTT' => 'nns',
    'TAG' => 'nnu',
    'GGA' => 'uns',
    'GTC' => 'nns',
    'TGC' => 'nnu',
    'TCA' => 'nus',
    'ATT' => 'nnu',
    'TAT' => 'nnu',
    'AAT' => 'nnu',
    'ACT' => 'nns',
    'CAA' => 'nnu',
    'GAC' => 'nnu',
    'GGT' => 'nns',
    'TCC' => 'nns',
    'TTT' => 'nnu',
    'AGG' => 'unu',
    'CGT' => 'nns',
    'ATA' => 'unu',
    'CAT' => 'nnu',
    'CGG' => 'uns',
    'GGG' => 'uns',
    'CCC' => 'nns',
    'GAG' => 'nnu',
    'TTA' => 'uuu',
    'CTA' => 'uns',
    'GAT' => 'nnu',
    'TCT' => 'nns',
    'TTC' => 'nnu',
    'GCG' => 'nns',
    'GGC' => 'nns',
    'GAA' => 'nnu',
    'GCT' => 'nns',
    'CCT' => 'nns'
  }

  # Public: Initialize a new instance of Codon
  #
  def initialize( codon )
    case codon.first
    when String
      @nuc_codon = codon
    when Array
      @nuc_codon = codon.map(&:last)
      @pos_codon = codon.map(&:first)
    else
      warn "Can't create codon from: #{codon.inspect}"
      raise
    end
  end

  def translate
    Bio::Sequence::NA.new(@nuc_codon.join).translate
  end

  # Check whether two codons code for the same aa
  #
  # @param [Array] codon_1 ['A','T','G']
  # @param [Array] codon_2 ['C','T','A']
  # @return [Boolean]
  def self.codons_syn?(codon_1, codon_2)
    codon_1.translate == codon_2.translate
  end

  # Check codon for being a stop codon
  #
  # @param [Array] codon ['T','A','G']
  # @return [Boolean]
  def self.stop_codon?(codon)
    translate(codon) == '*' ? true : false
  end

  # Public: Return coordinates of synonymous or nonsynonymous positions.
  #
  # Examples:
  #   poss('syn')
  #   # => [26, 27]
  #
  # @param [Array] codon
  # @return [Array] array of Integers
  def poss( syn )
    cod = SITE_SYNONYMITY[@nuc_codon.join]
    return [] unless cod

    @pos_codon
      .zip(cod.split(""))
      .select{|p| p.last == (syn=='syn' ? 's' : 'n')}
      .map(&:first)
  end

  def include?( nuc )
    @nuc_codon.include?(nuc)
  end

end
end
