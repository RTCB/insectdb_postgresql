require 'spec_helper'

describe Insectdb::MutationCount::Leushkin do

  describe '::process' do

    it 'should return 0,0 when passed multiple mutations' do

      Insectdb::MutationCount::Leushkin
        .process(codon: build(:codon), mutations: build_list(:mutation, 2))
        .should == {:syn => 0.0, :nonsyn => 0.0}

    end

    it 'should return 1,0 when passed a synonymous mutation' do

      codon = build(:codon, seq: 'ACT')
      mutations = [build(:mutation, pos: 3)]

      Insectdb::MutationCount::Leushkin
        .process(codon: codon, mutations: mutations)
        .should == {:syn => 1.0, :nonsyn => 0.0}

    end

    it 'should return 0,1 when passed one non-synonymous mutation' do

      codon = build(:codon, seq: 'ACT')
      mutations = [build(:mutation, pos: 1)]

      Insectdb::MutationCount::Leushkin
        .process(codon: codon, mutations: mutations)
        .should == {:syn => 0.0, :nonsyn => 1.0}

    end

    it "should return 0,0 when passed a nonexistent codon" do
    end


  end

end
