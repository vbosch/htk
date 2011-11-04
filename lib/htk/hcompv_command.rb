module Htk
  class HCompVCommand
    NAME = "HCompV"
    attr_reader :parameters
    def initialize
      initialize_valid_parameters
    end

    def initialize_valid_parameters(&proc)
      @parameters = CommandParameters.new
      @parameters.add_valid_parameter(:C,:single)
      @parameters.add_valid_parameter(:S,:single)
      @parameters.add_valid_parameter(:A,:binary)
      @parameters.add_valid_parameter(:D,:binary)
      @parameters.add_valid_parameter(:V,:binary)
      @parameters.add_valid_parameter(:f,:single)
      @parameters.add_valid_parameter(:l,:single)
      @parameters.add_valid_parameter(:m,:binary)
      @parameters.add_valid_parameter(:o,:single)
      @parameters.add_valid_parameter(:v,:single)
      @parameters.add_valid_parameter(:B,:binary)
      @parameters.add_valid_parameter(:F,:single)
      @parameters.add_valid_parameter(:G,:single)
      @parameters.add_valid_parameter(:H,:multy)
      @parameters.add_valid_parameter(:I,:multy)
      @parameters.add_valid_parameter(:L,:single)
      @parameters.add_valid_parameter(:M,:single)
      @parameters.add_valid_parameter(:X,:single)

      yield(self) unless proc.nil?
    end

    def run(config_atros)
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