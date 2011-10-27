module GenerateHtkLanguageModel
  require 'ap'
  require 'ruby-debug'
  class State
    attr_reader :id, :label, :type, :transitions
    def initialize(ex_id, ex_label,ex_type = :NORMAL)
     @id = ex_id
     @label = ex_label
     @type = ex_type
     @transitions = Hash.new
    end

    def label_sym
      [@type,@label.upcase.to_sym]
    end

    def to_s
      "#{@id}: #{@label}"
    end

    def number_of_transitions
      @transitions.size
    end

    def set_statistics(statistics_hash)
      @current_statistics = statistics_hash
    end

    def recalculate_probabilities(alpha)
      prior_count = child_count
      @transitions.each_value do |val|
        if prior_count == 0.0
          val[:probability] = 0.0
        elsif val[:to].label == "!NULL"
          val[:probability] =  Math.log(val[:to].child_count/prior_count,Math::E)
        else
          val[:probability] = Math.log(@current_statistics[val[:to].label_sym]/prior_count,Math::E)
        end
      end


      if label != "!NULL"
        temp = Hash.new
        @transitions.each_value do |val|
          if val[:to].label != "!NULL"
              val[:probability] = Math.log(@current_statistics[[label_sym,val[:to].label_sym]]/@current_statistics[label_sym],Math::E)
              temp[val[:to].id]=val if @current_statistics[[label_sym,val[:to].label_sym]] != 0.0
          end
        end
        @transitions = temp
      end


    end

    def child_label
      child = Array.new
      @transitions.each_value do |val|
           if val[:to].label == "!NULL"
             child.concat(val[:to].child_label)
           else
              child.push(val[:to].label_sym)
           end
        end
      child
    end

    def child_count
      count = 0.0
      @transitions.each_value{|val| count += val[:to].label == "!NULL" ? val[:to].child_count : @current_statistics[val[:to].label_sym]}
      count
    end

    def add_transition(state,probability)
      @transitions[state.id]={:to => state, :probability => probability}
    end
  end
end