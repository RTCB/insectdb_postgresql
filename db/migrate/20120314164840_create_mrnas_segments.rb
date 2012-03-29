class CreateMrnasSegments < ActiveRecord::Migration
  def change
    create_table :mrnas_segments do |t|
      t.integer :mrna_id
      t.integer :segment_id
    end

    add_index :mrnas_segments,
              [:mrna_id],
              :name => 'mrnas_segments__mrna_id_segment_id'
    add_index :mrnas_segments,
              [:segment_id],
              :name => 'mrnas_segments__segment_id_mrna_id'
  end
end
