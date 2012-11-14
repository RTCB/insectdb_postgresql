require 'spec_helper'

describe Insectdb::Codon do
describe "#pos_syn?" do
  it "should return true for third position in 'CGA' codon" do
    c = Insectdb::Codon.new([[5,'C'],[6,'G'],[7,'A']])
    c.pos_syn?(7).should == true
  end
end

end
