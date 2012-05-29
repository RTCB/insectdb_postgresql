require 'spec_helper'
require 'fakefs'

module Insectdb
  describe "bind" do
    it "should return positions clustered" do
      path = Insectdb::Config.path_to(:bind)
      FakeFS::FileSystem.add(File.dirname(path))

      File.open(path,'w') do |f|
        f << %W[
          1,0.01
          2,0.2
          3,0.03
          4,0.099
          5,0.1
          9,0.2
          11,3
        ].join("\n")
      end

      Insectdb.bind.should == [[1,3,4],[5],[2,9],[11]]
    end
  end
end
