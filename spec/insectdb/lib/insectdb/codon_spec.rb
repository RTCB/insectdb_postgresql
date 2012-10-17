require 'spec_helper'

describe Insectdb::Codon do
describe "#pos_syn?" do
  c = Insectdb::Codon.new([[5,'C'],[6,'G'],[7,'A']])
  c.pos_syn?(7).should == true
end
end
