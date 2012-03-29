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

  # @param [Array] nuc_codon ['A','T','G']
  # @param [Array] mut_codon [ nil, ['T','C'], nil ]
  def initialize( nuc_codon, mut_codon = nil )
    @nuc_codon = nuc_codon
    @mut_codon = prepare_mut_codon(mut_codon)
    @count     = {'syn' => 0.0, 'nonsyn' => 0.0}
  end

  # @example
  #   Codon.syn_coords_in([[25,'G'],[26,'T'],[27,'A']]) #=> [26]
  #
  # @param [Array] codon
  # @return [Array]
  def self.syn_coords_in( codon )
    cod = SITE_SYNONYMITY[codon.map(&:last).join]
    return [] unless cod

    codon.map(&:first)
         .zip(cod.split(''))
         .select{|p| p.last == 's'}
         .map(&:first)
  end

  # @example
  #   Codon.nonsyn_coords_in([[25,'G'],[26,'T'],[27,'A']]) #=> [27]
  #
  # @param [Array] codon
  # @return [Array]
  def self.nonsyn_coords_in( codon )
    cod = SITE_SYNONYMITY[codon.map(&:last).join]
    return [] unless cod

    codon.map(&:first)
         .zip(cod.split(''))
         .select{|p| p.last == 'n'}
         .map(&:first)
  end

  # Count synonymous and nonsynonymous mutations in codon
  def mut_count( simple=true )
    simple ? mut_count_simple : mut_count_complex
  end

  def mut_count_simple
    if @mut_codon.all?(&:nil?) or
       @mut_codon.compact.size > 1 then
      return {'syn' => 0, 'nonsyn' => 0}
    end

    mut_pos = @mut_codon.indexes_of{|a| !a.nil?}.first

    case SITE_SYNONYMITY[@nuc_codon.join][mut_pos]
    when 'u' then {'syn' => 0, 'nonsyn' => 0}
    when 's' then {'syn' => 1, 'nonsyn' => 0}
    when 'n' then {'syn' => 0, 'nonsyn' => 1}
    end
  end

  def mut_count_complex
    return {'syn' => 0, 'nonsyn' => 0} if @mut_codon.all?(&:nil?)

    final_count =
      SpliceEvo::MutPath
        .generate_paths_from_codon(self)
        .map(&:process)

    paths = final_count.compact.size
    return {'syn' => 0, 'nonsyn' => 0} if paths == 0

    final_count = final_count.compact.sum_hashes

    final_count['syn']    = final_count['syn'].to_f/paths
    final_count['nonsyn'] = final_count['nonsyn'].to_f/paths
    final_count
  end

  # Return number of synonymous sites in codon
  #
  # @param [String] codon 'ATG'
  # @return [Fixnum]
  def self.count_syn_sites( codon )
    cod = SITE_SYNONYMITY[codon] ? cod.count('s') : 0
  end

  # Return number of non-synonymous sites in codon
  #
  # @param [String] codon 'AGT'
  # @return [Fixnum]
  def self.count_nonsyn_sites( codon )
    cod = SITE_SYNONYMITY[codon] ? cod.count('n') : 0
  end

  # Translate nucleotide seq into aa
  #
  # @param [Array] codon ['A','T','G']
  # @return [String] single letter string identifier of aa
  def self.translate(codon)
    Bio::Sequence::NA.new(codon).translate
  end

  # Check whether two codons code for the same aa
  #
  # @param [Array] codon_1 ['A','T','G']
  # @param [Array] codon_2 ['C','T','A']
  # @return [Boolean]
  def self.codons_syn?(codon_1, codon_2)
    translate(codon_1) == translate(codon_2)
  end

  # Check codon for being a stop codon
  #
  # @param [Array] codon ['T','A','G']
  # @return [Boolean]
  def self.stop_codon?(codon)
    translate(codon) == '*' ? true : false
  end

  # Apply mutation on passed codon
  # @example
  #   Codon.apply_mutation( ['A','C','G'], ['A','T'], 0 )
  #     --> ['T','C','G']
  # @param [Array] codon
  # @param [Array] mutation
  # @param [Fixnum] pos
  # @return [Array]
  def self.apply_mutation( codon, mutation, pos)
    cod = codon.clone
    cod[pos] = mutation[1]
    cod
  end

  private

  # @param [Array] mut_codon
  def prepare_mut_codon( mut_codon )
    if mut_codon.nil? || mut_codon.all?(&:nil?)
      [nil,nil,nil]
    else
      m_codon = @nuc_codon.zip(mut_codon)
                          .map{|arr| arr.include?(nil) ? nil : orient(arr)}
                          .map{|arr| arr.nil? ? nil : arr[1] }
      m_codon.all?(&:nil?) ? nil : m_codon
    end
  end

  # @example
  #   orient( ['A',['A','C']] ) => ['A',['A','C']]
  #   orient( ['A',['C','A']] ) => ['A',['A','C']]
  #
  # @param [Array]
  # @return [Array]
  def orient( arr )
    if arr[0] == arr[1][0]
      return arr
    elsif arr[0] == arr[1][1]
      arr[1].reverse!
      return arr
    else
      nil
    end
  end

end
end
