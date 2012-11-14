module Insectdb
class Sequence
attr_reader :seq, :strand # Public: Instantiate the new Sequence object.  # # seq_with_coords - The Array with positions and nucleotides, i.e.  #                   [[1,'A'],[2,'G']]
  # strand - The String with + or - sign, denoting the read direction.
  #
  # Returns the Sequence object.
  def initialize( seq_with_coords, strand )
    @strand = strand
    case strand
    when '+'
      @seq = seq_with_coords
    when '-'
      @seq = seq_with_coords.reverse
    end
  end

  # Public: Return the array with nucleotides of this sequence.
  #
  # Examples:
  #
  #   Sequnce.new([[1,'A'],[2,'G']],'+').nuc_seq #=> ['A','G']
  #   Sequnce.new([[1,'A'],[2,'G']],'-').nuc_seq #=> ['G','A']
  #
  # Returns the Array.
  def nuc_seq
    @seq.map(&:last)
  end

  def []( pos )
    @seq.find { |a| a.first == pos }
  end

  def length
    @seq.length
  end

  def +( sequence )
    if @strand != sequence.strand
      raise ArgumentError, "Can't concatenate sequences from different strands"
    end

    seq = (@seq + sequence.seq).sort_by{ |e| e.first }
    case @strand
    when '+'
      Insectdb::Sequence.new(seq, @strand)
    when '-'
      Insectdb::Sequence.new(seq.reverse, @strand)
    end
  end

  def codon_at( position )
    return nil if length < 3
    pre_codon =
      @seq.each_slice(3)
          .find { |c| c.map(&:first).include?(position) && c.size == 3 }
    pre_codon ? Codon.new(pre_codon) : nil
  end

  # Public: Return the Array with Codon objects.
  def codons
    return [] if length < 3
    @seq.each_slice(3)
        .map { |c| c.size == 3 ? Insectdb::Codon.new(c) : nil }
        .compact
  end

  # Public: Return String with sequnce
  #
  # Examples:
  #
  #   Sequnce.new([[1,'A'],[2,'G']],'+').raw_seq #=> 'AG'
  def raw_seq
    @seq.map(&:last).join
  end

end
end
