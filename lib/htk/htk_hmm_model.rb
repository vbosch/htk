module Htk
  require 'ap'
  class HTKHMMModel

    SELF_TRANSITION_PROBABILITY=6.000e-01
    NEXT_TRANSITION_PROBABILITY=4.000e-01

    attr_reader :num_states
    attr_accessor :name,:states

    def initialize(ex_name,ex_num_states,ex_feature_space_dimension,&proc)
      @name = ex_name
      @num_states = ex_num_states
      @feature_space_dimension = ex_feature_space_dimension
      @self_prob = SELF_TRANSITION_PROBABILITY
      @next_prob = NEXT_TRANSITION_PROBABILITY
      yield(self) unless proc.nil?
      @states = Array.new
    end

    def HTKHMMModel.strictly_linear_hmm(ex_name,ex_num_states,ex_feature_space_dimension,&proc)
      model = HTKHMMModel.new(ex_name,ex_num_states,ex_feature_space_dimension,&proc)
      model.strictly_linear_state_initialization
      return model
    end

    def strictly_linear_state_initialization
      @states.push HTKHMMState.start_state(@feature_space_dimension,@num_states)
      1.upto(@num_states-2) do |pos|
        tmp=HTKHMMState.normal_state(@feature_space_dimension,pos,@num_states) do |state|
          state.self_prob = @self_prob
          state.next_prob=@next_prob
        end
        @states.push tmp
      end
      @states.push HTKHMMState.end_state(@feature_space_dimension,@num_states)
    end

    def  HTKHMMModel.ranged_linear_hmm(ex_name,range,ex_feature_space_dimension,&proc)
      model = HTKHMMModel.new(ex_name,range.last+1,ex_feature_space_dimension,&proc)
      model.ranged_linear_state_initialization(range)
      return model
    end

    def ranged_linear_state_initialization(range)
       @states.push HTKHMMState.start_state(@feature_space_dimension,@num_states)

       1.upto(@num_states-2) do |pos|
        tmp = HTKHMMState.normal_state(@feature_space_dimension,pos,@num_states) do |state|

          if range.include? pos
            if pos != @num_states - 2
              state.next_prob=0.5
              state.self_prob = 0.0
            else
              state.next_prob=0.4
              state.self_prob = 0.6
            end
          else
            state.self_prob = 0.0
            state.next_prob=1.0
          end
        end
        @states.push tmp
       end

      @states.push HTKHMMState.end_state(@feature_space_dimension,@num_states)

      range.each do |pos|
        @states[pos].transitions[-1]=0.5 if pos < @num_states-2
      end

    end

    def  HTKHMMModel.state_specified_hmm(ex_name,ex_feature_space_dimension,states,&proc)
      model = HTKHMMModel.new(ex_name,states.size,ex_feature_space_dimension,&proc)
      model.states = states
      return model
    end

    def write_as_composition(file)
      write_header(file)
      write_states(file)
      write_transitions(file)
      write_footer(file)
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
      file.puts "~h \"#{@name}\""
      file.puts "<BEGINHMM>"
    end

    def write_states(file)
      file.puts "<NUMSTATES> #{@num_states}"

      @states[1...@num_states-1].each do |state|
        file.puts state.distribution_to_s
      end

    end

    def set_state_distributions(mean,variance,gconst)
      @states[1...@num_states-1].each do |state|
        state.set_probability_distribution(mean,variance,gconst)
      end
    end

    def write_transitions(file)
      file.puts "<TRANSP> #{@num_states}"
      @states.each do |state|
        file.puts state.transition_to_s
      end
    end

    def write_footer(file)
      file.puts "<ENDHMM>"
    end



    def HTKHMMModel.read(lines,name,feature_space_dim)
      #lines = HTKHMMModel.read_model_lines(file)
      num_states = HTKHMMModel.extract_num_states(lines)
      states = HTKHMMModel.extract_states(lines,num_states,feature_space_dim)
      transitions =  HTKHMMModel.extract_transitions(lines)

      num_states.times do |state_index|
        states[state_index].transitions = transitions[state_index]
      end

      return HTKHMMModel.state_specified_hmm(name,feature_space_dim,states)
    end

    def HTKHMMModel.read_model_lines(file)
      line_array = []
      file.each_line do |line|
        line_array.push line
        break if is_end_hmm_line? line
      end
      return line_array
    end

    def HTKHMMModel.extract_num_states(lines)
      lines.each do |line|
        return HTKHMMModel.extract_num_states_value(line) if HTKHMMModel.is_num_states_line?(line)
      end
      return nil
    end

    def HTKHMMModel.extract_states(lines,num_states,feature_space_dim)
      old = -1
      current = -1
      states = []
      states.push HTKHMMState.start_state(feature_space_dim,num_states)
      lines.each_with_index do |line,index|
        if HTKHMMState.is_state_initial_line?(line) or HTKHMMModel.is_transition_initial_line?(line)

          old = current
          current = index
        end
        if old != -1 and current !=-1
          states.push HTKHMMState.read(lines[old...current],feature_space_dim)
          old = -1
        end
      end
      states.push HTKHMMState.end_state(feature_space_dim,num_states)
      raise "Less states found than indicated in the model" if states.size != num_states
      return states
    end




    def HTKHMMModel.extract_transitions(lines)
      transitions = []
      transition_index = lines.size+1
      num_values = -1
      lines.each_with_index do |line,index|
        if HTKHMMModel.is_transition_initial_line?(line)
          transition_index = index
          num_values=HTKHMMModel.extract_transition_size(line)
        end

        if index > transition_index and not HTKHMMModel.is_end_hmm_line?(line)
          transitions.push HTKHMMMixture.extract_values(line,num_values)
        end

      end
      raise "Different number of transitions found than specified" if num_values != transitions.size
      return transitions
    end



    def HTKHMMModel.is_name_line?(line)
      line =~ /~h/
    end

    def HTKHMMModel.extract_name(line)
      line.split[1].split("\"")[1]
    end

    def HTKHMMModel.is_start_hmm_line?(line)
      line =~ /<BEGINHMM>/
    end

    def HTKHMMModel.is_num_states_line?(line)
      line =~ /<NUMSTATES>/
    end

    def HTKHMMModel.extract_num_states_value(line)
      line.split[1].to_i
    end

    def HTKHMMModel.is_transition_initial_line?(line)
      line =~ /<TRANSP>/
    end

    def HTKHMMModel.extract_transition_size(line)
      line.split[1].to_i
    end

    def HTKHMMModel.is_end_hmm_line?(line)
      line =~ /<ENDHMM>/
    end

  end
end