class CreateReferences < ActiveRecord::Migration
  def change
    create_table :reference do |t|

      t.string  :chromosome
      t.integer :position
      t.string  :dmel
      t.string  :dsim
      t.string  :dyak
      t.boolean :dmel_dsim
      t.boolean :dmel_dyak
      t.boolean :dsim_dyak

    end
  end
end
