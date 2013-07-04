module Insectdb
class Codon

  attr_reader :codon

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

  # Public
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
    @nuc_codon ||= @codon.map(&:last)
  end

  def pos_codon
    @pos_codon ||= @codon.map(&:first)
  end

  def start
    pos_codon.first
  end

  def stop
    pos_codon.last
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

  # Public: Apply mutation onto this codon.
  #
  # Examples:
  #
  #   Insectdb::Codon.new([[1,'A'],[2,'C'],[3,'C']])
  #                  .mutate([2, ['C','G']])
  #
  # mutation -  An Array that is a simplified Snp or Div.
  #
  # Returns a Codon.
  def mutate( mutation )

    ind = @codon.index{ |a| a[0] == mutation.first }
    current_nuc = @codon[ind][1]
    new_nuc = mutate_nucleotide(current_nuc, mutation[1])

    # if mutation has no common nucleotides with this codon
    return nil unless new_nuc

    new_codon = @codon.clone
    new_codon[ind] = [mutation.first, new_nuc]

    Insectdb::Codon.new(new_codon)

  end

  # Private: Return a mutated nucleotide value for the
  # existing nucleotide and mutation pattern passed.
  def mutate_nucleotide( old_nuc, poly )

    poly.include?(old_nuc) ? poly.find{ |nuc| nuc != old_nuc } : nil

  end


end
end
