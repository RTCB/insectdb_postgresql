require 'spec_helper'

describe Insectdb::MutationCount::Ermakova do

    codon = Insectdb::Codon.new([[1,'A'],[2,'T'],[3,'T']])


    describe '::process' do

      it 'should return {true => 1.0, false => 0.0} given ATT with [3,[T,C]] mutation' do
        Insectdb::MutationCount::Ermakova
          .process(codon, [[3,['T','C']]])
          .should == {true => 1.0, false => 0.0}
      end

      it 'should return {true => 0.0, false => 0.0} given ATT with [3,[G,C]] mutation' do
        Insectdb::MutationCount::Ermakova
          .process(codon, [[3,['G','C']]])
          .should == {true => 0.0, false => 0.0}
      end

      it 'should return {true => 0.5, false => 0.5}  given ATT with [2,[T,C]] and [3,[T,A]] mutations' do
        Insectdb::MutationCount::Ermakova
          .process(codon, [ [2,['T','C']], [3,['T','A']] ])
          .should == {true => 0.5, false => 0.5}
      end

      it 'should return {true => 1.0, false => 0.0}  given ATT with [2,[G,C]] and [3,[T,A]] mutations' do
        Insectdb::MutationCount::Ermakova
          .process(codon, [ [2,['G','C']], [3,['T','A']] ])
          .should == {true => 1.0, false => 0.0}
      end

    end

    describe '::build_path' do

      it "for ATT and [2,[TC]] should return [ATT, ACT]" do
        Insectdb::MutationCount::Ermakova
          .build_path(codon, [[2,['T','C']]] )
          .map(&:nuc_codon)
          .map(&:join)
          .should == ['ATT', 'ACT']
      end

      it "for ATT and [2,[GC]] should return nil" do
        Insectdb::MutationCount::Ermakova
          .build_path(codon, [[2,['G','C']]] )
          .should == [codon, nil]
      end

    end

    describe '::process_path' do

      it 'should return [true] for [ATT, ATC]' do
        Insectdb::MutationCount::Ermakova
          .process_path(
            [
              Insectdb::Codon.new( [[1,'A'],[2,'T'],[3,'T']] ),
              Insectdb::Codon.new( [[1,'A'],[2,'T'],[3,'C']] )
            ])
          .should == [true]
      end

      it 'should return [true] for [ATT, ATC, nil]' do
        Insectdb::MutationCount::Ermakova
          .process_path(
            [
              Insectdb::Codon.new( [[1,'A'],[2,'T'],[3,'T']] ),
              Insectdb::Codon.new( [[1,'A'],[2,'T'],[3,'C']] ),
              nil
            ])
          .should == [true]
      end

    end


end
