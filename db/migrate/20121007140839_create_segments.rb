class CreateSegments < ActiveRecord::Migration
  def up
    create_table :segments do |t|
      t.integer :chromosome
      t.integer :start
      t.integer :stop
      t.integer :length
      t.string  :type
      t.text    :_ref_seq
    end

    add_index :segments,
              [:chromosome, :start, :stop],
              :name => 'segments__chr_start_stop'

    add_index :segments,
              [:type],
              :name => 'segments__type'
  end

  def down
    drop_table :segments
  end
end
