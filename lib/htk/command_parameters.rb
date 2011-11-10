module Htk
  class CommandParameters
    def initialize
      @parameter_values = Hash.new{:empty}
      @valid_parameters = Hash.new
    end

    def add_valid_parameter(param_name,type)
      if [:binary,:multy,:single].include?(type)
        @valid_parameters[param_name]=type
      else
        raise "invalid parameter type given"
      end
    end

    def []=(param_name,value)
      if @valid_parameters.include?(param_name)
        @parameter_values[param_name]=value
      else
        raise "Invalid parameter #{param_name} for command given"
      end

    end

    def to_s
      tmp = ""
        @parameter_values.each_key do |param_name|
          tmp << param_to_s(param_name)
        end
      tmp
    end

    def param_to_s(param_name)
      return binary_param_to_s(param_name) if @valid_parameters[param_name]==:binary
      return multy_param_to_s(param_name) if @valid_parameters[param_name]==:multy
      single_param_to_s(param_name)
    end

    def binary_param_to_s(param_name)
     return  " -#{param_name.to_s}" if @parameter_values[param_name] == true
      ""
    end

    def multy_param_to_s(param_name)
      tmp = ""
        if @parameter_values[param_name] != :empty
          tmp << " -#{param_name.to_s}"
          @parameter_values[param_name].each do |val|
            tmp << " #{val}"
          end
        end
      tmp
    end

    def single_param_to_s(param_name)
      return " -#{param_name.to_s} #{@parameter_values[param_name]}" if @parameter_values[param_name] != :empty
      ""
    end

  end
end