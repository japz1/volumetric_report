#$LOAD_PATH.unshift(File.expand_path('../../lib', __FILE__))
require 'byebug'
require 'rubygems'
require 'gnuplot'
#require "gnuplot"

#test data
def graph(data, patient_data, structures, path)
    #data = {"lhipp_vol"=>["20", "4173.87", "5077.18", "5421.26", "5738.26", "6465.38"], "rhipp_vol"=>["20", "4583.16", "5135.58", "5519.56", "5903.54", "6455.96"]}
  #data = [["20", "4173.87", "5077.18", "5421.26", "5738.26", "6465.38"], ["20", "4583.16", "5135.58", "5519.56", "5903.54", "6455.96"]]

  #patient_data = {"lhipp_vol"=>4861.15, "rhipp_vol"=>5726.77}
  #patient_data = [4861.15, 5726.77]
  #structures = ["lhipp_vol", "rhipp_vol"]

  # 1 1.5 2   2.4 4 6.
  # 2 1.5 3   3.5 4 5.5
  # 3 4.5 5   5.5 6 6.5
  #byebug
  if structures.length == 2
    x = [0,1]
    x1 = structures
    yp5 = [data[0][1].to_f,data[1][1].to_f]
    yp25 = [data[0][2].to_f,data[1][2].to_f]
    yp50 = [data[0][3].to_f,data[1][3].to_f]
    yp75 = [data[0][4].to_f,data[1][4].to_f]
    yp95 = [data[0][5].to_f,data[1][5].to_f] 
    point = patient_data
  else
    x = [0,1,2]
    x1 = structures
    yp5 = [data[0][1].to_f,data[1][1].to_f,data[2][1].to_f]
    yp25 = [data[0][2].to_f,data[1][2].to_f,data[2][2].to_f]
    yp50 = [data[0][3].to_f,data[1][3].to_f,data[2][3].to_f]
    yp75 = [data[0][4].to_f,data[1][4].to_f,data[2][4].to_f]
    yp95 = [data[0][5].to_f,data[1][5].to_f,data[2][5].to_f]
    point = patient_data
  end
 

  delta_y = (yp5+yp95+point).max - (yp5+yp95+point).min
  y_range = (((yp5+yp95+point).min - delta_y) < 0 ) ? 0 : ((yp5+yp95+point).min - delta_y) , (yp5+yp95+point).max + delta_y



  Gnuplot.open do |gp|
    Gnuplot::Plot.new( gp ) do |plot|
      plot.terminal "gif"
      plot.output File.expand_path("#{path}/#{x1[0]}_#{x1[1]}.gif")  
      plot.title  "Comparision with the Control Group"
      plot.ylabel "Normalized Volumes (mm^3)"
      plot.xlabel "Structures"
      plot.boxwidth "0.5"
      if structures.length == 2
        plot.xrange "[-1:2]"
      else
        plot.xrange "[-1:3]"
      end
      plot.yrange "[#{y_range[0]}:#{y_range[1]}]"

      #percentiles
      plot.data << Gnuplot::DataSet.new( [x,yp5,yp25,yp50,yp75,yp95] ) do |ds|
        ds.using = "1:3:2:6:5"
        ds.with = "candlesticks lt -1 lw 1 title 'percentiles' whiskerbars 0.5"
        #ds.notitle
      end

      #media
      plot.data << Gnuplot::DataSet.new( [x,yp5,yp25,yp50,yp75,yp95] ) do |ds|
        ds.using = "1:4:4:4:4"
        ds.with = "candlesticks lt -1 lw 1"
        ds.notitle
      end

      #punto
      plot.data << Gnuplot::DataSet.new( [x1,point] ) do |ds|
        ds.using = "($0):2:xtic(1)"
        ds.with = "points lt 3 pt 5 ps 1"
        ds.notitle
      end

    end
  end
  puts 'created figure'
end


