module Htk
  class HTKHMMState

    SELF_TRANSITION_PROBABILITY=6.000e-01
    NEXT_TRANSITION_PROBABILITY=4.000e-01

    attr_reader :position,:feature_space_dimension
    attr_accessor :self_prob, :next_prob, :transitions

    def initialize(position,feature_space_dim,&proc)
      @position = position

      @feature_space_dimension = feature_space_dim
      @mixtures = []
      @gconst = nil
      @self_prob = SELF_TRANSITION_PROBABILITY
      @next_prob = NEXT_TRANSITION_PROBABILITY
      yield(self) unless proc.nil?
    end

    def clear_mixtures
      @mixtures.clear
    end

    def [](val)
      @mixtures[val]
    end

    def add_basic_mixture(mix_probability=1.0)
      @mixtures.push HTKHMMMixture.new(@mixtures.size+1,mix_probability,@feature_space_dimension)
    end

    def add_detailed_mixture(mix_probability,mean,variance,gconst=nil)
      tmp= HTKHMMMixture.new(@mixtures.size+1,mix_probability,@feature_space_dimension)
      tmp.mean = mean
      tmp.variance = variance
      tmp.gconst = gconst
      @mixtures.push tmp
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
      @mixtures.each do |mix|
        mix.mean = ex_mean
        mix.variance = ex_variance
        mix.gconst = ex_gconst
      end
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
      "<STATE> #{@position+1}\n" + mixture_number_to_s + mixtures_to_s
    end

    def mixture_number_to_s
      return "" if @mixtures.size == 1
      "<NUMMIXES> #{@mixtures.size}\n"
    end

    def mixtures_to_s
      return @mixtures[0].simple_to_s if @mixtures.size == 1
      @mixtures.inject(""){|res,mix| res+=mix.full_to_s}
    end

    def transition_to_s
      @transitions.inject(""){|res,val| res+= "#{sprintf("%e",val)} "}
    end

  end
end
