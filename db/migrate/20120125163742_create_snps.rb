class CreateSnps < ActiveRecord::Migration
  def change
    create_table :snps do |t|

      t.integer :position
      t.string  :chromosome
      t.float   :abundance
      t.integer :amount
      t.text    :frequencies

    end

    add_index :snps,
              [:chromosome, :position, :abundance, :amount],
              :name => 'snps__chromosome_pos_abundance_amount'
  end
end
