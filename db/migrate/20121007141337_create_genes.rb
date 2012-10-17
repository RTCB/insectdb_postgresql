class CreateGenes < ActiveRecord::Migration
  def up
    create_table :genes do |t|
      t.string  :flybase_id
    end
  end

  def down
    drop_table :genes
  end
end
