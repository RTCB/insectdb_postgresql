class CreateSegments < ActiveRecord::Migration
  def change
    create_table :segments do |t|

      t.string  :chromosome
      t.integer :start
      t.integer :stop
      t.string  :type

    end

    add_index :segments,
              [:chromosome, :type],
              :name => 'segments__chr_type'
    add_index :segments,
              [:type],
              :name => 'segments__type'
  end
end
