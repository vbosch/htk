module Htk
  class HTKHMMState

   SELF_TRANSITION_PROBABILITY=6.000e-01
   NEXT_TRANSITION_PROBABILITY=4.000e-01

   attr_reader :position,:feature_space_dimension
   attr_accessor :self_prob, :next_prob, :mean, :variance, :gconst

   def initialize(position,feature_space_dim,&proc)
    @position = position

    @feature_space_dimension = feature_space_dim
    @mean = Array.new(@feature_space_dimension,0.0)
    @variance = Array.new(@feature_space_dimension,1.0)
    @gconst = nil
    @self_prob = SELF_TRANSITION_PROBABILITY
    @next_prob = NEXT_TRANSITION_PROBABILITY
    yield(self) unless proc.nil?
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

   def HTKHMMState.start_state(feature_space_dimension,num_states)
     tmp=HTKHMMState.new(0,feature_space_dimension)
     tmp.initialize_transitions(num_states,:start)
     tmp
   end
   def HTKHMMState.end_state(feature_space_dimension,num_states)
     tmp =  new(num_states-1,feature_space_dimension)
     tmp.initialize_transitions(num_states,:end)
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
      "<STATE> #{@position+1}\n" + mean_to_s + variance_to_s + gconst_to_s
    end

    def mean_to_s
      @mean.inject("<MEAN> #{@feature_space_dimension}\n"){|res,val| res+= "#{val.to_s} "}+"\n"
    end

   def variance_to_s
     @variance.inject("<VARIANCE> #{@feature_space_dimension}\n"){|res,val| res+= "#{val.to_s} "}+"\n"
   end

   def gconst_to_s
    return "<GCONST> #{@gconst}" unless @gconst.nil?
    ""
   end

    def transition_to_s
      @transitions.inject(""){|res,val| res+= "#{sprintf("%e",val)} "}

    end



  end
end
