require 'spec_helper'

describe Insectdb::Mrna do
describe "#ref_seq" do
  it "should return a valid ref_seq" do
    Insectdb::Segment.create!(
      :id => 1,
      :chromosome => '0',
      :start => 1,
      :stop => 2,
      :length => 2,
      :type => 'coding(const)',
      :_ref_seq => Insectdb::Sequence.new([[1,'A'],[2,'T']])
    )
    Insectdb::Segment.create!(
      :id => 2,
      :chromosome => '0',
      :start => 5,
      :stop => 7,
      :length => 3,
      :type => 'coding(const)',
      :_ref_seq => Insectdb::Sequence.new([[5,'G'],[6,'G'],[7,'C']])
    )
    Insectdb::Mrna.create!(
      :id => 1,
      :chromosome => 0,
      :strand => '+',
      :start => 1,
      :stop => 7
    )
    Insectdb::MrnasSegments.create!(
      :segment_id => 1,
      :mrna_id => 1
    )
    Insectdb::MrnasSegments.create!(
      :segment_id => 2,
      :mrna_id => 1
    )

    Insectdb::Mrna.first
                  .ref_seq
                  .seq_with_coords
                  .should == [[1,'A'],[2,'T'],[5,'G'],[6,'G'],[7,'C']]
  end
end
end
