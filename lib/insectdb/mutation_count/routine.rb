module Insectdb::MutationCount
class Routine

  def initialize( segment: segment, method: 'leushkin')

    @snps    = segment.snps.map(&:to_mut)
    @divs    = segment.divs.map(&:to_mut)
    @codons  = segment.codons
    @method  = method

  end

  def pn_ps
    mut_map(muts: @snps).map{ |s| mutcount(s) }
                        .reduce{ |one, two| one.merge(two){ |k,v1,v2| v1+v2 } }
  end

  def mutcount( struct: struct )
    Insectdb::MutationCount.const_get(@method.capitalize)
                           .process(struct.codon, struct.mutations)
  end

  # Creates an array with OpesStructs. Struct is comprised of a codon
  # and mutations associated with it. Only Structs with more than zero mutations
  # find its way into the resulting array.
  def mut_map( muts: muts)
    aggregate_muts(muts: muts).compact
  end

  def aggregate_muts( muts: muts )
    mut = nil
    @codons.map{ |c| muts_for_codon(codon: c, muts_enum: muts.each, mut: mut) }
  end

  def muts_for_codon( codon: codon, muts_enum: muts_enum, mut: mut)

    mut_set = []

    while codon.last >= (mut ||= muts_enum.next).pos do
      mut_set << mut
      mut = muts_enum.next
    end

    mut_set.empty? ? nil : OpenStruct.new(codon: c, mutations: mut_set)

  end


end
end
