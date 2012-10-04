require 'spec_helper'

describe Insectdb::SeqEnum do

before(:each) {@seq = Insectdb::SeqEnum.new('ATG', false)}

describe '#new' do

  it "initializes correctly from string" do
    seq = Insectdb::SeqEnum.new('ACG', false)
    seq.seq.join.should == 'ACG'
  end

  it "initializes correctly from gzip file" do
    file = '/var/tmp/stub.gz'

    Zlib::GzipWriter.open(file) do |gz|
      gz.write ">id\nAGT\nGGC"
    end

    seq = Insectdb::SeqEnum.new(file)
    seq.seq.join.should == "AGTGGC"
  end

  it "sanitizes the sequnce from nucleotide letters in lower case" do
    seq = Insectdb::SeqEnum.new('ACGggT', false)
    seq.seq.join.should == 'ACGNNT'
  end
end

describe "::next" do
  it "returns the first nucleotide if called for the first time" do
    @seq.next.should == 'A'
  end
  it "should return N when out of next nucleotides" do
    3.times{ @seq.next }
    @seq.next.should == 'N'
  end
end

describe "::rewind" do
  it "rewinds the sequence iteration, so that ::next can start from the beginning" do
    20.times{ @seq.next }
    @seq.rewind
    @seq.next.should == 'A'
  end
end

end
