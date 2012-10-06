require 'spec_helper'

describe Insectdb::Snp do

describe "::from_col" do
  it "should initialize correctly from nucleotide column" do
    Insectdb::Snp.from_col('AAGANNG'.split(''), '2R', 123)
    s = Insectdb::Snp.first
    s.chromosome.should == 0
    s.sig_count.should == 5
    s.alleles.should == {'A' => 3, 'G' => 2}
  end
end

describe "::column_is_polymorphic?" do
  it "should return true for [A A C] column" do
    Insectdb::Snp.column_is_polymorphic?(%W[ A A C ]).should be_true
  end

  it "should return true for [A G C] column" do
    Insectdb::Snp.column_is_polymorphic?(%W[ A G C ]).should be_true
  end

  it "should return false for [A A N] column" do
    Insectdb::Snp.column_is_polymorphic?(%W[ A A N ]).should be_false
  end

  it "should return false for [A A A] column" do
    Insectdb::Snp.column_is_polymorphic?(%W[ A A A ]).should be_false
  end

  it "should return false for [N N N] column" do
    Insectdb::Snp.column_is_polymorphic?(%W[ N N N ]).should be_false
  end

  it "should return false for empty column" do
    Insectdb::Snp.column_is_polymorphic?([]).should be_false
  end
end

end
