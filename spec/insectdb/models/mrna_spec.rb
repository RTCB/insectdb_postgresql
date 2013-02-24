require 'spec_helper'

describe Insectdb::Mrna do

describe "#ref_seq" do
  it "should return a valid ref_seq" do
    Insectdb::Segment.___create!(
      :id => 1,
      :chromosome => '2R',
      :start => 1,
      :stop => 2,
      :length => 2,
      :type => 'coding(const)',
      :_ref_seq => Insectdb::Sequence.new([[1,'A'],[2,'T']])
    )
    Insectdb::Segment.___create!(
      :id => 2,
      :chromosome => '2R',
      :start => 5,
      :stop => 7,
      :length => 3,
      :type => 'coding(const)',
      :_ref_seq => Insectdb::Sequence.new([[5,'G'],[6,'G'],[7,'C']])
    )
    Insectdb::Mrna.___create!(
      :id => 1,
      :chromosome => '2R',
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
                  .seq
                  .should == [[1,'A'],[2,'T'],[5,'G'],[6,'G'],[7,'C']]
  end
end

describe "#validity_check" do

  context "for + strand mRNAs" do

    it "should return true if ref_seq starts with ATG" do

      Insectdb::Mrna.___create!(
        :id => 1,
        :chromosome => '2R',
        :strand => '+',
        :start => 1,
        :stop => 7,
        :_ref_seq => Insectdb::Sequence.new(
          [[1, 'A'],[2, 'T'],[3, 'G'],[4, 'C']]
        )
      )

      Insectdb::Mrna.first.validity_check.should be_true

    end

    it "should return false if ref_seq does not start with ATG" do

      Insectdb::Mrna.___create!(
        :id => 1,
        :chromosome => '2R',
        :strand => '+',
        :start => 1,
        :stop => 7,
        :_ref_seq => Insectdb::Sequence.new(
          [[1, 'C'],[2, 'T'],[3, 'G'],[4, 'C']]
        )
      )

      Insectdb::Mrna.first.validity_check.should be_false

    end

  end

  context "for - strand mRNAs" do

    it "should return true if ref_seq ends with CAT" do

        Insectdb::Mrna.___create!(
            :id => 1,
            :chromosome => '2R',
            :strand => '-',
            :start => 1,
            :stop => 7,
            :_ref_seq => Insectdb::Sequence.new(
                [[1, 'A'],[2, 'C'],[3, 'A'],[4, 'T']]
            )
        )

        Insectdb::Mrna.first.validity_check.should be_true

    end

    it "should return false if ref_seq doesn't end with CAT" do

        Insectdb::Mrna.___create!(
            :id => 1,
            :chromosome => '2R',
            :strand => '-',
            :start => 1,
            :stop => 7,
            :_ref_seq => Insectdb::Sequence.new(
                [[1, 'A'],[2, 'C'],[3, 'A'],[4, 'G']]
            )
        )

        Insectdb::Mrna.first.validity_check.should be_false

    end

  end

end

end
