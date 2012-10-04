require 'spec_helper'

describe Insectdb::Seed do
describe "::reference_enums" do
  it "returns a hash with SeqEnum objects for dmel, dsim and dyak reference genomes" do
    cf = lambda do |name, content|
      FileUtils.mkdir_p(File.dirname(name))
      Zlib::GzipWriter.open(name){ |gz| gz.write(content) }
    end

    cf.call("/var/tmp/drosophila_melanogaster/dm3_2R.fa.gz", ">dm3\nAAA\nCCC")
    cf.call("/var/tmp/drosophila_simulans/droSim1_2R.fa.gz", ">droSim1\nTTT\nGGG")
    cf.call("/var/tmp/drosophila_yakuba/droYak2_2R.fa.gz",   ">droYak\nGGG\nTTT")

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
  it "processes sequence data"

end

end
end
