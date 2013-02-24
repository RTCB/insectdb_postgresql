# require 'spec_helper'
# 
# describe Insectdb::Reference do
# 
#   Insectdb::Reference.create!(
#     :dmel => 'G',
#     :dsim => 'G',
#     :dyak => 'G',
#     :chromosome => 0,
#     :position => 123
#   )
#   Insectdb::Reference.create!(
#     :dmel => 'T',
#     :dsim => 'G',
#     :dyak => 'G',
#     :chromosome => 0,
#     :position => 124
#   )
#   Insectdb::Reference.create!(
#     :dmel => 'C',
#     :dsim => 'C',
#     :dyak => 'C',
#     :chromosome => 0,
#     :position => 125
#   )
# 
#   describe "#ref_seq" do
#     it "returns a correct reference sequence" do
# 
#         Insectdb::Reference
#             .ref_seq('2R', 123, 125)
#             .nuc_seq
#             .join
#             .should == "GNC"
# 
#     end
#   end
# 
# end
# end
