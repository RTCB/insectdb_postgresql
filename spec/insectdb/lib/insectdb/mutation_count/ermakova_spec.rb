require 'spec_helper'

describe Insectdb::MutationCount::Ermakova do

    describe '::process' do

      codon = FactoryGirl::build(:codon, seq: 'ATT')
      let(:mutations) { Array.new }

      it 'should return {true => 1.0, false => 0.0} given ATT with [3,[TC]] mutation' do
        pending

        mutations << build(:mutation, pos: 3, alleles: 'TC')

        Insectdb::MutationCount::Ermakova
          .process(codon: codon, mutations: mutations)
          .should == {true => 1.0, false => 0.0}

      end

      it 'should return {true => 0.0, false => 0.0} given ATT with [3,[GC]] mutation' do
        pending

        mutations << build(:mutation, pos: 3, alleles: 'GC')

        Insectdb::MutationCount::Ermakova
          .process(codon: codon, mutations: mutations)
          .should == {true => 0.0, false => 0.0}

      end

      it 'should return {true => 0.5, false => 0.5}  given ATT with [2,[TC]] and [3,[TA]] mutations' do
        pending

        mutations << build(:mutation, pos: 2, alleles: 'TC')
        mutations << build(:mutation, pos: 3, alleles: 'TA')

        Insectdb::MutationCount::Ermakova
          .process(codon: codon, mutations: mutations)
          .should == {true => 0.5, false => 0.5}

      end

      it 'should return {true => 1.0, false => 0.0}  given ATT with [2,[GC]] and [3,[TA]] mutations' do
        pending

        mutations << build(:mutation, pos: 2, alleles: 'GC')
        mutations << build(:mutation, pos: 3, alleles: 'TA')

        Insectdb::MutationCount::Ermakova
          .process(codon: codon, mutations: mutations)
          .should == {true => 1.0, false => 0.0}

      end

    end

end
