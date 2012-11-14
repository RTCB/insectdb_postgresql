module Insectdb
class Mrna < ActiveRecord::Base
  serialize :_ref_seq

  # has_and_belongs_to_many :genes
  has_and_belongs_to_many :segments

  validates :chromosome,
            :presence => true,
            :numericality => { :only_integer => true },
            :inclusion => { :in => [0, 1, 2, 3, 4] }

  validates :start,
            :presence => true,
            :numericality => { :only_integer => true }

  validates :stop,
            :presence => true,
            :numericality => { :only_integer => true }

  validates :strand,
            :presence => true,
            :inclusion => { :in => %W[ + - ] }

  def self.___create!( params )
    Insectdb::Mrna.create! do |r|
      r.id         = params[:id].to_i
      r.chromosome = Insectdb::CHROMOSOMES[params[:chromosome]]
      r.strand     = params[:strand]
      r.start      = params[:start].to_i
      r.stop       = params[:stop].to_i
    end
  end

  def self.clean
    Insectdb.peach(Mrna.all, 20) do |m|
      m.delete if m.segments.empty?
    end
    nil
  end

  # Public: Make all mRNAs generate their reference sequences by calling
  #         their Mrna#ref_seq method. This function does this in 5
  #         parallel threads.
  #
  # Returns nothing.
  def self.set_ref_seq
    Insectdb.peach(Insectdb::CHROMOSOMES.values, 5) do |chr|
      Mrna.where(:chromosome => chr).each(&:ref_seq)
    end
    nil
  end

  # Public: Return codon that includes this position.
  #
  # Returns the Codon object.
  def codon_at( position )
    ref_seq.codon_at(position)
  rescue => e
    warn "-"*30
    warn self.inspect
    warn e.inspect
    warn "-"*30
    raise
  end

  def ref_seq
    if _ref_seq
      _ref_seq
    else
      seq = segments.map(&:ref_seq).reduce(:+)
      update_attributes(:_ref_seq => seq)
      seq
    end
  rescue => e
    warn "-"*30
    warn self.inspect
    warn e.inspect
    warn "-"*30
    return Insectdb::Sequence.new([], '+')
  end

end
end
