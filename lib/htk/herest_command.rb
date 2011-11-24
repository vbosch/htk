module Htk
  class HERestCommand
    NAME = "HERest"
    attr_reader :parameters
    attr_accessor :train_file, :list
    def initialize(&proc)
      initialize_valid_parameters
      @list = nil
      @train_file=""
      yield(self) unless proc.nil?
    end

    def initialize_valid_parameters
      @parameters = CommandParameters.new
      @parameters.add_valid_parameter(:C,:single)
      @parameters.add_valid_parameter(:S,:single)
      @parameters.add_valid_parameter(:A,:binary)
      @parameters.add_valid_parameter(:D,:binary)
      @parameters.add_valid_parameter(:V,:binary)
      @parameters.add_valid_parameter(:T,:single)

      @parameters.add_valid_parameter(:c,:single)
      @parameters.add_valid_parameter(:d,:single)
      @parameters.add_valid_parameter(:m,:single)
      @parameters.add_valid_parameter(:o,:single)
      @parameters.add_valid_parameter(:p,:single)
      @parameters.add_valid_parameter(:r,:single)
      @parameters.add_valid_parameter(:s,:single)
      @parameters.add_valid_parameter(:t,:single)
      @parameters.add_valid_parameter(:u,:single)
      @parameters.add_valid_parameter(:v,:single)
      @parameters.add_valid_parameter(:x,:single)
      @parameters.add_valid_parameter(:B,:binary)
      @parameters.add_valid_parameter(:F,:single)
      @parameters.add_valid_parameter(:G,:single)
      @parameters.add_valid_parameter(:H,:multy)
      @parameters.add_valid_parameter(:I,:multy)
      @parameters.add_valid_parameter(:L,:single)
      @parameters.add_valid_parameter(:M,:single)
      @parameters.add_valid_parameter(:X,:single)
    end

    def run(config_atros=nil)
      if config_atros.nil?
        @list.do_with_file do
            system to_s
        end
      else
        run_with_config(config_atros)
      end
    end

    def run_with_config(config_atros)
      @parameters[:C]=config_atros.name
      config_atros.do_with_file do
        @list.do_with_file do
            system to_s
        end
      end
    end

    def to_s
      "#{NAME}#{@parameters.to_s} #{@list.name} #{train_file}"
    end

  end
end