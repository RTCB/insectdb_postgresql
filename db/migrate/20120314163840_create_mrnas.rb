class CreateMrnas < ActiveRecord::Migration
  def change
    create_table :mrnas do |t|

      t.string  :chromosome
      t.string  :strand
      t.integer :start
      t.integer :stop

    end
  end
end
