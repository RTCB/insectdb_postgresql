class CreateMrnas < ActiveRecord::Migration
  def up
    create_table :mrnas do |t|
      t.integer :chromosome
      t.string  :strand
      t.integer :start
      t.integer :stop
      t.text    :_ref_seq
    end
  end

  def down
    drop_table :mrnas
  end
end
