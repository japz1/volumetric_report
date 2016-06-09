$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
#require "gnuplot"

# 1 1.5 2   2.4 4 6.
# 2 1.5 3   3.5 4 5.5
# 3 4.5 5   5.5 6 6.5
x = [0,1,2]
x1 = ["strucA","strucB"]
yp5 = [1.5, 1.5, 4.5]
yp25 = [2,3,5]
yp50 = [2.4, 3.5, 5.5]
yp75 = [4,4,6]
yp95 = [6,5.5, 6.5] 
point = [2,3]
require 'rubygems'
require 'gnuplot'
Gnuplot.open do |gp|
  Gnuplot::Plot.new( gp ) do |plot|
    plot.terminal "gif"
    plot.output File.expand_path("../figure.gif", __FILE__)  
    plot.title  "Comparision with the Control Group"
    plot.ylabel "Normalized Volumes (mm^3)"
    plot.xlabel "Structures"
    plot.boxwidth "0.2"
    plot.xrange "[-1:4]"
    plot.yrange "[0:10]"

    #percentiles
    plot.data << Gnuplot::DataSet.new( [x,yp5,yp25,yp50,yp75,yp95] ) do |ds|
      ds.using = "1:3:2:6:5"
      ds.with = "candlesticks lt 3 lw 2 title 'Quartiles' whiskerbars"
      #ds.notitle
    end

    #media
    plot.data << Gnuplot::DataSet.new( [x,yp5,yp25,yp50,yp75,yp95] ) do |ds|
      ds.using = "1:4:4:4:4"
      ds.with = "candlesticks lt -1 lw 2"
      ds.notitle
    end

    #punto
    plot.data << Gnuplot::DataSet.new( [x1,point] ) do |ds|
      ds.using = "($0):2:xtic(1)"
      ds.with = "points lt rgb 'red' "
      ds.notitle
    end

  end
end

puts 'created figure.gif'
