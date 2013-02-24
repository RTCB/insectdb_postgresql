require 'spec_helper'

describe Insectdb::Sequence do

describe "#initialize" do
    it "should correctly initialize" do
        Insectdb::Sequence.new([[123,'A'], [124,'T'], [125,'G']])
          .class.should == Insectdb::Sequence
    end
end

describe "#nuc_seq" do

  it "should return correct data" do
    Insectdb::Sequence.new([[123,'A'], [124,'T'], [125,'G']])
      .nuc_seq.should == ['A', 'T', 'G']
  end

end

describe "#+" do

  a = Insectdb::Sequence.new([[1,'A'],[2,'G']])
  b = Insectdb::Sequence.new([[4,'G'],[5,'T']])

  c = Insectdb::Sequence.new([[1,'A'],[2,'G']])
  d = Insectdb::Sequence.new([[4,'G'],[5,'T']])

  it "returns an Insectdb:Sequence object" do
    (a+b).class.should == Insectdb::Sequence
  end

  context "for the sum of two sequences" do

    it "correctly concatenates sequences " do
      (a+b).seq.should == [[1,'A'],[2,'G'],[4,'G'],[5,'T']]
    end

    it "is commutative" do
      (a+b).seq.should == (b+a).seq
    end

  end

describe "#codon_at" do

  it "should return a correct codon for 3-nucleotide sequence" do

    Insectdb::Sequence.new([[1,'A'],[2,'G'],[3,'C']])
      .codon_at(2)
      .nuc_codon
      .should == %W[ A G C ]

  end

  it "should return a correct codon for 7-nucleotide sequence" do

    Insectdb::Sequence.new([[1,'A'],[2,'G'],[3,'C'],[4,'C'],
                            [9,'G'],[10,'C'],[13,'T']])
      .codon_at(10)
      .nuc_codon
      .should == %W[ C G C ]

  end

  it "should return nil for position that is not present" do

    Insectdb::Sequence.new([[1,'A'],[2,'G'],[3,'C']])
      .codon_at(5)
      .should be_nil

  end

  it "should return nil for position at incomplete triplet" do

    Insectdb::Sequence.new([[1,'A'],[2,'G'],[3,'C'],[5,'T']])
      .codon_at(5)
      .should be_nil

  end

  it "should return nil if sequence is less than 3 bases long" do

    Insectdb::Sequence.new([[1,'A'],[2,'G']])
      .codon_at(2)
      .should be_nil

  end

end

end

describe "#to_s" do
  it "should all the sequence if it is shorter than 14 NA" do
    Insectdb::Sequence.new([[1,'A'],[2,'G']])
                      .to_s
                      .should == 'AG'
  end
end

end
