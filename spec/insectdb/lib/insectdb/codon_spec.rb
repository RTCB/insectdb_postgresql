require 'spec_helper'

describe Insectdb::Codon do


let(:codon) { build(:codon, seq: 'ATC') }

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

  it "should return ATG for ATC with mutation CG at position 3" do

    mutation = build(:mutation, pos: 3, seq: 'CG')

    codon.mutate(mutation)
         .should == build(:codon, alleles: 'ATG')

  end

  it "should return nil for ATC with mutation TG at position 3" do

    mutation = build(:mutation, pos: 3, alleles: 'TG')

    codon.mutate(mutation)
         .should be_nil
  end

end

end
