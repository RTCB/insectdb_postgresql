require 'spec_helper'

describe Insectdb::MutationCount::Leushkin do

  describe '::process' do

    codon = Insectdb::Codon.new([[1,'A'],[2,'C'],[3,'T']])

    mutation_1 = Insectdb::Mutation.new(pos: 1, alleles: ['A','T'])
    mutation_2 = Insectdb::Mutation.new(pos: 3, alleles: ['G','C'])

    set_1 = [mutation_1, mutation_2]
    set_2 = [mutation_2]
    set_3 = [mutation_1]

    it 'should return 0,0 when passed multiple mutations' do

      Insectdb::MutationCount::Leushkin
        .process(codon: codon, mutations: set_1)
        .should == {:syn => 0.0, :nonsyn => 0.0}

    end

    it 'should return 1,0 when passed a synonymous mutation' do

      Insectdb::MutationCount::Leushkin
        .process(codon: codon, mutations: set_2)
        .should == {:syn => 1.0, :nonsyn => 0.0}

    end

    it 'should return 0,1 when passed one non-synonymous mutation' do

      Insectdb::MutationCount::Leushkin
        .process(codon: codon, mutations: set_3)
        .should == {:syn => 0.0, :nonsyn => 1.0}

    end

  end

end
