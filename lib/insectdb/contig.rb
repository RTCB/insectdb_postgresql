module Insectdb
class Contig

  attr_reader :nuc_seq, :start

  #      5'---------------->3'
  #    start              stop
  # @param [String] nuc_seq --> 'ACGTTTG'
  # @param [Fixnum] start, counted from 5' end
  # @param [String] strand '+' or '-'
  def initialize( nuc_seq, start, strand )
    @start = start
    @nuc_seq = ( strand == '+' ? nuc_seq : comp_seq(nuc_seq) )
    @strand = strand
  end

  def count( nuc )
    @nuc_seq.count(nuc)
  end

  # Return nucleotide at position.
  #
  # @param [Fixnum] pos
  # @return [String] nucleotide at passed pos
  def []( pos )
    @nuc_seq[(pos-@start)]
  end

  # Contig length
  #
  # @return [Fixnum]
  def length
    @nuc_seq.length
  end

  # Return the array of positions.
  #
  # @return [Array] [12,13,14,15,16,17]
  def positions
    (start...(start+length)).to_a
  end

  # Complement the passed nucleotide.
  #
  # @param [String] nuclotide
  # @return [String]
  def self.complement( nucleotide )
    case nucleotide
    when 'A' then 'T'
    when 'G' then 'C'
    when 'T' then 'A'
    when 'C' then 'G'
    when 'N' then 'N'
    else
      warn "can't return complementary nucleotide for --> #{nucleotide}"
      nil
    end
  end

  private

  def comp_seq(seq)
    seq.chars.map{|n| Insectdb::Contig.complement(n)}.join
  end

end
end
