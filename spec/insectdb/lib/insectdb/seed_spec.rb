require 'spec_helper'

describe Insectdb::Seed do

# A helper function that produces a gzipped file with passed content
def cf( path, content )
  FileUtils.mkdir_p(File.dirname(path))
  Zlib::GzipWriter.open(path){ |gz| gz.write(content) }
end

describe "::reference_enums_for" do
  it "returns a hash with SeqEnum objects for dmel,
      dsim and dyak reference genomes" do

    cf("/var/tmp/drosophila_melanogaster/dm3_2R.fa.gz",
            ">dm3\nAAA\nCCC")
    cf("/var/tmp/drosophila_simulans/droSim1_2R.fa.gz",
            ">droSim1\nTTT\nGGG")
    cf("/var/tmp/drosophila_yakuba/droYak2_2R.fa.gz",
            ">droYak\nGGG\nTTT")

    Insectdb::Seed.reference_enums_for('2R', '/var/tmp')
                  .map{ |k,v| [k, v.seq.join] }
                  .to_hash
                  .should == {
                    :dmel => 'AAACCC',
                    :dsim => 'TTTGGG',
                    :dyak => 'GGGTTT'
                  }
  end

describe "::seq_processor" do
  it "should add Div when no Snp is found" do
    Insectdb::Seed.seq_processor(
      {:dmel => 'A', :dsim => 'G', :dyak => 'G'},
      ['A']*163,
      '2R',
      70943
    )

    Insectdb::Div.count.should == 1
    Insectdb::Snp.count.should == 0
    Insectdb::Reference.count.should == 1
  end

  it "should not add Div or Snp when both are present" do
    Insectdb::Seed.seq_processor(
      {:dmel => 'A', :dsim => 'G', :dyak => 'G'},
      (['A']*162) + ['C'],
      '2R',
      70943
    )

    Insectdb::Div.count.should == 0
    Insectdb::Snp.count.should == 0
    Insectdb::Reference.count.should == 1
  end
end

describe "::seqs" do
  it "should produce correct records in the database" do
    cf("/var/tmp/drosophila_melanogaster/dm3_2L.fa.gz",
            ">dm3\nAAACCC")
    cf("/var/tmp/drosophila_melanogaster/Line911_2L.fa.gz",
            ">dm3\nAAACCC")
    cf("/var/tmp/drosophila_melanogaster/Line921_2L.fa.gz",
            ">dm3\nATACCC")
    cf("/var/tmp/drosophila_melanogaster/Line931_2L.fa.gz",
            ">dm3\nAAACCC")
    cf("/var/tmp/drosophila_simulans/droSim1_2L.fa.gz",
            ">droSim1\nTATGGG")
    cf("/var/tmp/drosophila_yakuba/droYak2_2L.fa.gz",
            ">droYak\nGAGGTT")

    Insectdb::Seed._seqs('/var/tmp', '2L')
    Insectdb::Snp.first.position.should == 2
    Insectdb::Div.first.position.should == 4
    Insectdb::Reference.first.dsim.should == 'T'
  end
end

end

end
