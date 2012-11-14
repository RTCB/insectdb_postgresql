require 'spec_helper'

describe Insectdb::Segment do
before(:each) do
    Insectdb::Reference.create!(
      :dmel       => 'G',
      :dsim       => 'G',
      :dyak       => 'G',
      :chromosome => 0,
      :position   => 1
      )
    Insectdb::Reference.create!(
      :dmel       => 'T',
      :dsim       => 'T',
      :dyak       => 'T',
      :chromosome => 0,
      :position   => 2
      )
    Insectdb::Reference.create!(
      :dmel       => 'T',
      :dsim       => 'G',
      :dyak       => 'T',
      :chromosome => 0,
      :position   => 3
      )
    Insectdb::Segment.___create!(
      :id         => 1,
      :chromosome => '2R',
      :start      => 1,
      :stop       => 3,
      :length     => 3,
      :type       => 'coding(const)'
      )
    Insectdb::Mrna.___create!(
      :id         => 1,
      :chromosome => '2R',
      :strand     => '+',
      :start      => 1,
      :stop       => 3
      )
    Insectdb::MrnasSegments.create!(
      :segment_id => 1,
      :mrna_id => 1
    )
end

describe "#ref_seq" do
  it "should return the correct Contig object" do
    Insectdb::Segment.first
                     .ref_seq
                     .seq
                     .should == [[1,'G'], [2,'T'], [3, 'N']]
  end
end

describe "::codon_at" do
  it "should return the correct Codon" do
    Insectdb::Segment.codon_at(0, 2).nuc_codon.join.should == "GTN"
  end
end

end
