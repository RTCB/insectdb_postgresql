require 'spec_helper'

describe Insectdb::Segment do

describe "#ref_seq" do
  it "should return the correct object" do
    build(:segment)
      .ref_seq
      .seq
      .should == [[1,'A'],[2,'T'],[3,'G']]
  end
end

describe "#codons" do
  it "should return all codons of this segment" do
    build(:segment)
      .codons
      .map(&:codon)
      .should ==
        [Insectdb::Codon.new([[1,'A'], [2,'T'], [3, 'G']]).codon]
  end
end

end
