require 'spec_helper'

describe Insectdb::Div do

describe "::from_hash" do
  it "should create a correct record in database" do
    Insectdb::Div.from_hash('2R', 1234)
    r = Insectdb::Div.first
    r.chromosome.should == 0
    r.position.should == 1234
  end
end

describe "::position_is_divergent?" do
  it "should return true for [A G G] case" do
    Insectdb::Div.position_is_divergent?({ :dmel => 'A',
                                           :dsim => 'G',
                                           :dyak => 'G',}).should be_true
  end

  it "should return false for [A N N] case" do
    Insectdb::Div.position_is_divergent?({ :dmel => 'A',
                                           :dsim => 'N',
                                           :dyak => 'N',}).should be_false
  end

  it "should return false for [N A A] case" do
    Insectdb::Div.position_is_divergent?({ :dmel => 'N',
                                           :dsim => 'A',
                                           :dyak => 'A',}).should be_false
  end

  it "should return false for [N N N] case" do
    Insectdb::Div.position_is_divergent?({ :dmel => 'N',
                                           :dsim => 'N',
                                           :dyak => 'N',}).should be_false
  end

  it "should return false for [A G C] case" do
    Insectdb::Div.position_is_divergent?({ :dmel => 'A',
                                           :dsim => 'G',
                                           :dyak => 'C',}).should be_false
  end
end

end
