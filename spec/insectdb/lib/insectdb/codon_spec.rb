require 'spec_helper'

describe Insectdb::Codon do

codon = Insectdb::Codon.new([[1,'A'], [2,'T'], [3,'C']])

describe "#pos_codon" do
  it "should an array with coordinates" do
    codon.pos_codon.should == [1,2,3]
  end
end

describe "#start" do
  it "should return coordinate of the first position" do
    codon.start.should == 1
  end
end

describe "#mutate" do

  it "should return ATG for ATC with mutation [3,[C,G]]" do
    codon.mutate([3,['C','G']])
         .nuc_codon
         .should == ['A','T','G']
  end

  it "should return nil for ATC with mutation [3,[T,G]]" do
    codon.mutate([3,['T','G']])
         .should be_nil
  end

end

end
