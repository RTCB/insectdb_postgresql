class CreateAll < ActiveRecord::Migration

  def up
    create_snps
    create_reference
    create_segments
    create_mrnas
    create_genes
    create_mrnas_segments
    create_genes_mrnas
  end

  def create_reference
    create_table :reference do |t|
      t.integer :chromosome
      t.integer :position
      t.string  :dmel
      t.string  :dsim
      t.string  :dyak
      t.boolean :dmel_dsim
      t.boolean :dsim_dyak
    end

    add_index :reference,
              [:chromosome, :position, :dmel_dsim],
              :name => 'ref__dmel_dsim'

    add_index :reference,
              [:chromosome, :position, :dsim_dyak],
              :name => 'ref__dsim_dyak'
  end

  def create_snps
    create_table :snps do |t|
      t.integer :chromosome
      t.integer :position
      t.integer :sig_count
      t.text    :alleles
      t.boolean :synonymous
    end

    add_index :snps,
              [:chromosome, :position, :sig_count, :synonymous],
              :name => 'snps__chr_pos_sigcount_synonymous'
  end

  def create_segments
    create_table :segments do |t|
      t.integer :chromosome
      t.integer :start
      t.integer :stop
      t.integer :length
      t.string  :type
      t.text    :supp
    end

    # Insectdb::Segment.seed(Insectdb::Config::PATH[:segments])

    add_index :segments,
              [:chromosome, :type],
              :name => 'segments__chr_type'

    add_index :segments,
              [:type],
              :name => 'segments__type'
  end

  def create_mrnas
    create_table :mrnas do |t|
      t.integer :chromosome
      t.string  :strand
      t.integer :start
      t.integer :stop
      t.text   :supp
    end

    # Insectdb::Mrna.seed(Insectdb::Config::PATH[:mrnas])
  end

  def create_genes
    create_table :genes do |t|
      t.integer :chromosome
      t.string  :flybase_id
    end
  end

  def create_mrnas_segments
    create_table :mrnas_segments do |t|
      t.integer :mrna_id
      t.integer :segment_id
    end

    add_index :mrnas_segments,
              [:mrna_id],
              :name => 'mrnas_segments__mrna_id'
    add_index :mrnas_segments,
              [:segment_id],
              :name => 'mrnas_segments__segment_id'
  end

  def create_genes_mrnas
    create_table :genes_mrnas do |t|
      t.integer :gene_id
      t.integer :mrna_id
    end

    add_index :genes_mrnas,
              [:gene_id],
              :name => 'genes_mrnas__gene_id'

    add_index :genes_mrnas,
              [:mrna_id],
              :name => 'genes_mrnas__mrna_id'
  end

end
