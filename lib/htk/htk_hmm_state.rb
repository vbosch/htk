module Htk
  class HTKHMMState

    SELF_TRANSITION_PROBABILITY=6.000e-01
    NEXT_TRANSITION_PROBABILITY=4.000e-01

    attr_reader :position,:feature_space_dimension
    attr_accessor :self_prob, :next_prob, :transitions

    def initialize(position,feature_space_dim,&proc)
      @position = position

      @feature_space_dimension = feature_space_dim
      @mixture_set = HTKHMMMixtureSet.new(@feature_space_dimension)
      @mixture_type = :personal
      @self_prob = SELF_TRANSITION_PROBABILITY
      @next_prob = NEXT_TRANSITION_PROBABILITY
      yield(self) unless proc.nil?
    end

    def clear_emission_probability
      @mixture_set.clear
    end

    def [](val)
      @mixture_set[val]
    end

    def set_mixture_set(set)
      @mixture_set = set
    end

    def add_basic_mixture(mix_probability=1.0)
      @mixture_set.add_basic_mixture(mix_probability)
    end

    def add_detailed_mixture(mix_probability,mean,variance,gconst=nil)
      @mixture_set.add_detailed_mixture(mix_probability,mean,variance,gconst)
    end

    def initialize_transitions(num_states,state_type)
      @transitions = Array.new(num_states,0.0)
      @state_type = state_type
      case @state_type
        when :start
          start_transition_initialization
        when :normal
          normal_transition_initialization
      end
    end

    def set_probability_distribution(ex_mean,ex_variance,ex_gconst)
      @mixture_set.set_probability_distribution(ex_mean,ex_variance,ex_gconst)
    end

    def HTKHMMState.start_state(feature_space_dimension,num_states)
      tmp=HTKHMMState.new(0,feature_space_dimension)
      tmp.initialize_transitions(num_states,:start)
      tmp.add_basic_mixture
      tmp
    end
    def HTKHMMState.end_state(feature_space_dimension,num_states)
      tmp =  new(num_states-1,feature_space_dimension)
      tmp.initialize_transitions(num_states,:end)
      tmp.add_basic_mixture
      tmp
    end

    def HTKHMMState.normal_state(feature_space_dimension,pos,num_states,&proc)
      tmp =  new(pos,feature_space_dimension,&proc)
      tmp.initialize_transitions(num_states,:normal)
      tmp.add_basic_mixture
      tmp
    end

    def normal_transition_initialization
      @transitions[@position]=@self_prob
      @transitions[@position+1]=@next_prob
    end

    def start_transition_initialization

      @transitions[@position+1]=1.0
    end

    def distribution_to_s
      "<STATE> #{@position+1}\n" + emission_probability_to_s
    end

    def emission_probability_to_s
      return @mixture_set.to_s
    end

    def transition_to_s
      @transitions.inject(""){|res,val| res+= "#{sprintf("%e",val)} "}
    end

    def HTKHMMState.read(lines,feature_space_dim)
      state_number = HTKHMMState.extract_state_number(lines)
      state = HTKHMMState.new(state_number,feature_space_dim)
      lines.shift
      set = HTKHMMMixtureSet.read(lines,feature_space_dim)
      state.set_mixture_set(set)
      return state
    end

    def HTKHMMState.extract_state_number(lines)
      lines.each do |line|
        return extract_state_number_value(line)-1 if is_state_initial_line? line
      end
    end

    def HTKHMMState.is_state_initial_line?(line)
      line =~ /<STATE>/
    end

    def HTKHMMState.extract_state_number_value(line)
      line.split[1].to_i
    end

  end
end
