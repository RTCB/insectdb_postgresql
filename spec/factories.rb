FactoryGirl.define do

  factory(:segment, :class => Insectdb::Segment) do
    sequence(:id)
    chr '2R'
    start 1
    type 'coding(const)'
    seq 'ATG'

    initialize_with { Insectdb::Segment.simple_create(attributes) }
  end

  factory(:snp, :class => Insectdb::Snp) do
    sequence(:id)
    position 1
    chromosome 0
    sig_count 160
    alleles Hash["T"=>150, "G"=>10]
  end

  factory(:codon, :class => Insectdb::Codon) do
    start 1
    seq 'ATG'
    initialize_with { Insectdb::Codon.simple_create(attributes)}
  end

  factory(:mutation, :class => Insectdb::Mutation) do
    sequence(:pos)
    alleles 'AG'

    initialize_with { Insectdb::Mutation.new(attributes) }
  end

end
