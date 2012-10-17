require 'spec_helper'

describe Insectdb::Sequence do
describe "#pos_seq" do
  it "should return correct data" do
    c = Insectdb::Sequence.new([[123,'A'], [124,'T'], [125,'G']])
  end
end

describe "#+" do
  it "should sum with another sequence" do
    c = Insectdb::Sequence.new([[1,'A'],[2,'G']])
    b = Insectdb::Sequence.new([[4,'G'],[5,'T']])
    (c+b).seq_with_coords.should == [[1,'A'],[2,'G'],[4,'G'],[5,'T']]
  end
end
end
