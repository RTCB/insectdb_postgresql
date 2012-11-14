require 'spec_helper'

describe Insectdb::Reference do
describe "#seq_for" do
  Insectdb::Reference.create!(
    :dmel => 'A',
    :dsim => 'G',
    :dyak => 'G',
    :chromosome => 0,
    :position => 123
  )
  Insectdb::Reference.create!(
    :dmel => 'T',
    :dsim => 'G',
    :dyak => 'G',
    :chromosome => 0,
    :position => 124
  )
  contig = Insectdb::Reference.ref_seq('2R', 123, 124, '+')
  # contig.nuc_seq.join.should == "AT"
end
end
