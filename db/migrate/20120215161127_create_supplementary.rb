class CreateSupplementary < ActiveRecord::Migration
  def change
    create_table :supp do |t|

      t.integer :segment_id
      t.text    :supp

    end

    add_index :supp,
              [:segment_id],
              :name => 'supp__segment_id'
  end
end
