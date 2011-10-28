module Htk
  class HTKHMMModel

    SELF_TRANSITION_PROBABILITY=6.000e-01
    NEXT_TRANSITION_PROBABILITY=4.000e-01

    attr_reader :name, :num_states

    def initialize(ex_name,ex_num_states,ex_feature_space_dimension,&proc)
      @name = ex_name
      @num_states = ex_num_states + 2
      @feature_space_dimension = ex_feature_space_dimension
      @self_prob = SELF_TRANSITION_PROBABILITY
      @next_prob = NEXT_TRANSITION_PROBABILITY
      yield(self) unless proc.nil?
      initialize_states
    end

    def initialize_states
      @states = Array.new

      @states.push HTKHMMState.start_state(@feature_space_dimension,@num_states)

      1.upto(@num_states-2) do |pos|
        tmp = HTKHMMState.new(pos,@feature_space_dimension){|state| state.self_prob = @self_prob;state.next_prob=@next_prob}
        tmp.initialize_transitions(@num_states,:normal)
        @states.push tmp
      end

      @states.push HTKHMMState.end_state(@feature_space_dimension,@num_states)
    end

    def write
      File.open(@name,"w") do |file|
        write_header(file)
        write_states(file)
        write_transitions(file)
        write_footer(file)
      end
    end

    def write_header(file)
      file.puts "~o <VecSize> #{@feature_space_dimension} <MFCC>"
      file.puts "~h \"#{@name}\""
      file.puts "<BeginHMM>"
    end

    def write_states(file)
      file.puts "<NumStates> #{@num_states}"

      @states[1...@num_states-1].each do |state|
        file.puts state.distribution_to_s
      end

    end

    def write_transitions(file)
      file.puts "<TransP> #{@num_states}"
      @states.each do |state|
        file.puts state.transition_to_s
      end
    end

    def write_footer(file)
      file.puts "<EndHMM>"
    end

    def self.load(file_name)

    end
  end
end