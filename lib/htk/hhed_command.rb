module Htk
  class HHEdCommand
    NAME = "HHEd"
    attr_reader :parameters
    attr_accessor :edit_chain, :list
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
      @parameters.add_valid_parameter(:T,:single)
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
        @list.do_with_file do
          @edit_chain.do_with_file do
            system to_s
          end
        end
      else
        run_with_config(config_atros)
      end
    end

    def run_with_config(config_atros)
      @parameters[:C]=config_atros.name
      config_atros.do_with_file do
        @list.do_with_file do
          @edit_chain.do_with_file do
            system to_s
          end
        end
      end
    end

    def to_s
      "#{NAME}#{@parameters.to_s} #{@edit_chain.name} #{@list.name}"
    end

  end
end