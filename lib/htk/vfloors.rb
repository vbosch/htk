module Htk
  class VFloors
    def initialize(ex_name,ex_num_variance,ex_variances)
      @name = ex_name
      @num_variance = ex_num_variance
      @variances = ex_variances
    end

    def write(file_name)
      write_to_descriptor( File.open(file_name,"w"))
    end

    def write_to_descriptor(file)
      write_name(file)
      write_variance_description(file)
      write_variances(file)

    end

    def write_name(file)
      file.puts "~v #{@name}"
    end

    def write_variance_description(file)
      file.puts "<VARIANCE> #{@num_variance}"
    end

    def write_variances(file)
      file.puts @variances.inject(""){|res,val| res += "#{val} "}.strip
    end

    def VFloors.load(file_name)
      raise "specified file does not exist" unless File.exists? file_name
      VFloors.load_from_file_descriptor(File.open(file_name,"r"),"")
    end

    def VFloors.load_from_lines(file,name)

      num_variance = -1
      variances = nil

      file.each_line do |line|
        if is_vfloor_name_line? line
          name = extract_vfloor_name(line)
        elsif is_num_variances_line? line
          num_variance = extract_num_variances(line)
        else
          variances =  extract_values(line,num_variance)
          return VFloors.new(name,num_variance,variances)
        end
      end
      return nil
    end

    def VFloors.load_from_file_descriptor(file,name)

      num_variance = -1
      variances = nil

      file.each_line do |line|
        if is_vfloor_name_line? line
          name = extract_vfloor_name(line)
        elsif is_num_variances_line? line
          num_variance = extract_num_variances(line)
        else
          variances =  extract_values(line,num_variance)
          return VFloors.new(name,num_variance,variances)
        end
      end
      return nil
    end

    def VFloors.is_vfloor_name_line?(line)
      line =~ /~v/
    end

     def VFloors.extract_vfloor_name(line)
      line.split[1]
     end

    def VFloors.is_num_variances_line?(line)
      line =~ /<VARIANCE>/ or line =~ /<Variance>/
    end

    def VFloors.extract_num_variances(line)
      line.split[1].to_i
    end

    def VFloors.extract_values(line,num_values)
      values = line.split
      raise "incorrect number of values found" if values.size != num_values
      values.map{|value| value.to_f}
    end

  end
end