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



    def HTKHMMModel.read(file,name,vec_size)
      status = :init
      state_status = :init
      model = nil
      num_states,num_values  = -1,-1,-1
      current_state = -1
      file.each_line do |line|
        case status
          when :init
            if is_start_hmm_line? line
              status = :num_states
            end
          when :num_states
            if is_num_states_line? line
              num_states = extract_num_states line
              model = HTKHMMModel.new(name,num_states,vec_size)
              status = :read_states
            else
              raise "After a <BEGINHMM> tag line <NUMSTATES> is expected"
            end
          when :read_states
            if is_state_initial_line? line
              current_state = extract_state_number(line)-1
              state_status = :read_state
            elsif is_state_mean_line? line and state_status == :read_state
              num_values = extract_state_mean line
              state_status = :mean_header
            elsif state_status == :mean_header
              model.states[current_state].mean = extract_values(line,num_values)
              state_status = :read_mean
            elsif is_state_variance_line? line and state_status == :read_mean
              num_values = extract_state_variance line
              state_status = :variance_header
            elsif state_status == :variance_header
              model.states[current_state].variance = extract_values(line,num_values)
              state_status = :read_variance
            elsif is_state_gconst_line? line  and state_status == :read_variance
              model.states[current_state].gconst= extract_gconst line
              state_status = :init
            elsif is_transition_initial_line? line
              status = :read_transitions
              current_state = 0
            end
          when :read_transitions
            if is_end_hmm_line? line
              status = :end
              return model
            elsif
              model.states[current_state].transitions= extract_values(line,num_states)
              current_state +=1
            end
        end
      end
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

    def HTKHMMModel.extract_num_states(line)
      line.split[1].to_i
    end

    def HTKHMMModel.is_end_hmm_line?(line)
      line =~ /<ENDHMM>/
    end

    def HTKHMMModel.is_state_initial_line?(line)
      line =~ /<STATE>/
    end

    def HTKHMMModel.extract_state_number(line)
      line.split[1].to_i
    end


    def HTKHMMModel.is_state_variance_line?(line)
      line =~ /<VARIANCE>/
    end

    def HTKHMMModel.extract_state_variance(line)
      line.split[1].to_i
    end

    def HTKHMMModel.is_state_mean_line?(line)
      line =~ /<MEAN>/
    end

    def HTKHMMModel.extract_state_mean(line)
      line.split[1].to_i
    end

    def HTKHMMModel.extract_values(line,num_values)
      values = line.split
      raise "incorrect number of values found" if values.size != num_values
      values.map{|value| value.to_f}
    end

    def HTKHMMModel.is_state_gconst_line?(line)
      line =~ /<GCONST>/
    end

    def HTKHMMModel.extract_gconst(line)
      line.split[1].to_f
    end

    def HTKHMMModel.is_transition_initial_line?(line)
      line =~ /<TRANSP>/
    end

  end
end