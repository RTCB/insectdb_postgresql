require 'spec_helper'

describe Insectdb::MutationCount::Routine do

describe "#muts_for_codon" do

  it "should select muts from enum that belong to codon" do

    codon = Insectdb::Codon.new([[1,'A'], [2,'T'], [3,'C']])
    segment = Insectdb::Segment.new
    segment.stubs(:snps).returns

  end
end


  it "" do
  end

end
