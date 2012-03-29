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

    add_index :reference,
              [:chromosome, :position],
              :name => 'reference__chromosome_pos'
    add_index :reference,
              [:chromosome, :dmel_dsim],
              :name => 'reference__chromosome_dmel_dsim'
    add_index :reference,
              [:chromosome, :dmel_dyak],
              :name => 'reference__chromosome_dmel_dyak'
    add_index :reference,
              [:chromosome, :dsim_dyak],
              :name => 'reference__chromosome_dsim_dyak'
    add_index :reference,
              [:chromosome, :dmel_dsim, :dmel_dyak, :dsim_dyak],
              :name => 'reference__chromosome_dmel_dsim_dyak'
  end
end
