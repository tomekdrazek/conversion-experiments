


F = 4

_y = [ 3, 4, 5, 6 ]

# permutation


# Calculate distance in n-th dim env
# v - input vector [x,y] -> 2^2 = 4 or [x,y,z] -> 2^3 = 8 or [c,m,y,k] -> 2^4=16
# f - probe freqency in each dim

def calc_d(v,f)
  [0,1].repeated_permutation(v.count).map do |l|
    s=0; l.each_with_index { |k,i| s+= (f*k-v[i])**2 }; Math.sqrt(s)
  end
end

def sum(a)
  s = 0; a.each { |e| s = s + e }; s
end

dim = 2
F.times.to_a.repeated_permutation(dim).each do |k|
  s=calc_d(k, F)
  puts "#{k} -> #{s} = #{sum(s)}"
end
