module Insectdb
  def self.mapp( array, processes = 8, &block )
    Parallel.map(array, :in_processes => processes) do |el|
      ActiveRecord::Base.connection.reconnect!
      block.call(el)
    end
  end

  def self.peach( array, processes = 8, &block )
    Parallel.each(array, :in_processes => processes) do |el|
      ActiveRecord::Base.connection.reconnect!
      block.call(el)
    end
  end

  def self.bench(&block)
    loop do
      a = block.call
      sleep(3)
      puts (block.call-a)
    end
  end

  def self.bind( path )
    data =
      File.open(path)
        .lines
        .map{ |li| l=li.chomp.split(","); l[0]=l[0].to_i; l[1]=l[1].to_f; l }
        .sort_by(&:last)

    holder = [[]]
    prev = 0
    ind = 0

    data.each do |b|
      (ind+=1; holder << []) if (prev != (nxt = (b.last*10).to_i))
      holder[ind] << b.first
      prev = nxt
    end

    holder
  end

  def self.aloha( arr, syn, query, filename )
    File.open(filename, 'a') do |f|
      f << arr.join("-")
      f << "\t"
      f << self.divs_with_nucs(syn, query, arr[1], arr[0])[2]
      f << "\n"
    end
  end

  # @param [String] syn 'syn' or 'nonsyn'
  # @param [ActiveRecord::Relation] query Insectdb::Segment.alt
  def self.freqs( syn, query )
    spread =
      Insectdb.mapp(query, 16){|s| s.freqs_at(s.poss(syn))}
              .flatten
              .reduce(Hash.new(0)){|h,v| h[v]+=1;h}
              .sort_by(&:first)
    sum = spread.map(&:last).inject(:+)
    spread.map{|a| (a[1] = a[1].to_f/sum);a }
  end

  def self.pn_ps_dn_ds_for( query )
    s = query.map(&:count_syn_sites).reduce(:+)
    n = query.map(&:count_nonsyn_sites).reduce(:+)

    self.mapp(query){|seg| [seg.pn_ps, seg.dn_ds].flatten }
        .compact
        .reduce([0,0,0,0]){|s,n| s.map.with_index{|v,ind| v+n[ind]} }
        .map.with_index{|v,ind| ind%2==0 ? v/n : v/s}
  end

  def self.divs_bind( path )
    bind = self.bind(path).map(&:first)
    bind = bind.each_slice(bind.size/100).to_a
    self.mapp((0..99).to_a, 4){|i| Div.count('2L', bind[i]) }
  end
end
