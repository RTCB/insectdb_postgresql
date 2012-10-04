require 'spec_helper'

describe Insectdb::Snp do
  DatabaseCleaner.clean_with :truncation
  before(:each) { DatabaseCleaner.start }
  after(:each) { DatabaseCleaner.clean }
  describe "::from_col" do
    it "should initialize correctly from nucleotide column" do
      Insectdb::Snp.from_col('AAGANNG'.split(''), 0, 123)
      s = Insectdb::Snp.first
      s.sig_count.should == 5
      s.alleles.should == {'A' => 3, 'G' => 2}
    end
  end
end
