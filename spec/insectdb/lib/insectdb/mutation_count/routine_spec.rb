require 'spec_helper'

describe Insectdb::MutationCount::Routine do

describe "#pn_ps" do
  it "should return a Hash object" do
    create(:snp)
    Insectdb::MutationCount::Routine
      .new(segment: build(:segment))
      .pn_ps
      .class
      .should == Hash
  end

  it "should return a Hash with keys :syn and :nonsyn" do
    create(:snp)
    Insectdb::MutationCount::Routine
      .new(segment: build(:segment))
      .pn_ps
      .keys
      .should == [:syn, :nonsyn]
  end
end

describe "#muts_for_codon_slow" do

  it "should select muts from enum that belong to codon" do
    3.times { |i| create(:snp, position: i+2) }
    segment = build(:segment)

    routine = Insectdb::MutationCount::Routine.new(segment: segment)

    routine.muts_for_codon_slow( codon: segment.codons.first,
                                 muts:  segment.snps.map(&:to_mutation))
           .mutations
           .map(&:pos)
           .should == [2,3]
  end
end

end
