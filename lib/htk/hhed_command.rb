module Htk
  class HHEdCommand
    NAME = "HHEd"
    attr_reader :parameters
    def initialize(&proc)
      initialize_valid_parameters
      yield(self) unless proc.nil?
    end

    def initialize_valid_parameters
      @parameters = CommandParameters.new
      @parameters.add_valid_parameter(:C,:single)
      @parameters.add_valid_parameter(:S,:single)
      @parameters.add_valid_parameter(:A,:binary)
      @parameters.add_valid_parameter(:D,:binary)
      @parameters.add_valid_parameter(:V,:binary)

      @parameters.add_valid_parameter(:d,:single)
      @parameters.add_valid_parameter(:o,:single)
      @parameters.add_valid_parameter(:w,:single)
      @parameters.add_valid_parameter(:x,:single)
      @parameters.add_valid_parameter(:z,:binary)
      @parameters.add_valid_parameter(:B,:binary)
      @parameters.add_valid_parameter(:H,:multy)
      @parameters.add_valid_parameter(:M,:single)
      @parameters.add_valid_parameter(:Q,:binary)
    end

    def run(config_atros=nil)
      if config_atros.nil?
        system to_s
      else
        run_with_config(config_atros)
      end
    end

    def run_with_config(config_atros)
      @parameters[:C]=config_atros.name
      config_atros.do_with_file do
        system to_s
      end
    end

    def to_s
      "#{NAME}#{@parameters.to_s}"
    end

  end
end