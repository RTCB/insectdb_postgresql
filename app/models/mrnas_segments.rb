module Insectdb
class MrnasSegments < ActiveRecord::Base
  self.table_name = 'mrnas_segments'

  def self.seed( path )
    File.open(File.join(path,'mrnas_segments'),'r') do |f|
      f.lines.each do |l|
        l = l.chomp.split
        seg = self.new do |seg|
          seg.mrna_id = l[0].to_i
          seg.segment_id = l[1].to_i
          seg.save
        end
      end
    end
  end

end
end
