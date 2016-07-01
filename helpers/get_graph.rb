def graph(data, patient_data, structures, path)

title = "BRAIN"  if structures.length ==  1
title = structures[1][6..-1].capitalize if structures.length ==  2 
title = "GREY-MATTER, P-CORTEX-GM, WHITE-MATTER" if structures.length ==  3


  if structures.length == 1
    x = [0]
    x1 = structures
    yp5 = [data[0][1].to_f]
    yp25 = [data[0][2].to_f]
    yp50 = [data[0][3].to_f]
    yp75 = [data[0][4].to_f]
    yp95 = [data[0][5].to_f] 
    point = patient_data
  elsif structures.length == 2
    x = [0,1]
    x1 = structures
    yp5 = [data[0][1].to_f,data[1][1].to_f]
    yp25 = [data[0][2].to_f,data[1][2].to_f]
    yp50 = [data[0][3].to_f,data[1][3].to_f]
    yp75 = [data[0][4].to_f,data[1][4].to_f]
    yp95 = [data[0][5].to_f,data[1][5].to_f] 
    point = patient_data
  elsif structures.length == 3
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
  y_range = (((yp5+yp95+point).min - delta_y/2) < 0 ) ? 0 : ((yp5+yp95+point).min - delta_y/2) , (yp5+yp95+point).max + delta_y/2



  Gnuplot.open do |gp|
    Gnuplot::Plot.new( gp ) do |plot|
      plot.terminal "png"
      plot.output File.expand_path("#{path}/#{x1[0]}_#{x1[1]}.png")  
      plot.title  "#{title}"
      plot.ylabel "Normalized Volumes (mm^3)"
      plot.xlabel "Structures"
      plot.boxwidth "0.5"
      if structures.length == 1
        plot.xrange "[-1:1]"
      elsif structures.length == 2
        plot.xrange "[-1:2]"
      elsif structures.length == 3
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

      #point
      plot.data << Gnuplot::DataSet.new( [x1,point] ) do |ds|
        ds.using = "($0):2:xtic(1)"
        ds.with = "points lt 3 pt 5 ps 1"
        ds.notitle
      end

    end
  end
  puts 'created figure'
end


