module Insectdb
class Codon

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

  attr_reader :codon

  # Public: Initialize a new instance.
  #
  # codon - The Array of this structure: [[1,'A'],[2,'G'],[3,'C']]
  #
  # Returns The Codon object.
  def initialize( codon )
    if (codon.class != Array) ||
       (codon.size != 3)
      raise ArgumentError,
            "Codon must have three bases, but this was passed: #{codon}"
    end
    @codon = codon
  end

  def nuc_codon
    @codon.map(&:last)
  end

  def pos_codon
    @codon.map(&:first)
  end

  def translate
    Bio::Sequence::NA.new(nuc_codon.join).translate
  end

  def valid?
    !nuc_codon.include?('N')
  end

  # Public: Does this codon have this position?
  #
  # pos - The Integer with position.
  #
  # Examples:
  #
  #   Insectdb::Codon.new([[1,'A'],[2,'B'],[3,'C']]).has_pos?(2) #=> true
  #   Insectdb::Codon.new([[1,'A'],[2,'B'],[3,'C']]).has_pos?(7) #=> false
  #
  # Returns The Boolean.
  def has_pos?( pos )
    pos_codon.include?(pos)
  end

  def pos_syn?( pos )
    cod = SITE_SYNONYMITY[nuc_codon.join]
    return nil unless cod

    case  pos_codon.zip(cod.split("")).find{ |p| p.first == pos }.last
    when 'u'
      nil
    when 's'
      true
    when 'n'
      false
    end
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
    cod = SITE_SYNONYMITY[nuc_codon.join]
    return [] unless cod

    pos_codon
      .zip(cod.split(""))
      .select{|p| p.last == (syn=='syn' ? 's' : 'n')}
      .map(&:first)
  end

  def include?( nuc )
    nuc_codon.include?(nuc)
  end

end
end
