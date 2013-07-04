FactoryGirl.define do
  factory :segment do
    id 1
    chromosome 0
    start 1
    stop 6
    type 'coding(alt)'
    length 6
    _ref_seq Insectdb::Sequence.new([[1,'A'],[2,'T'],[3,'G']])
  end
end
