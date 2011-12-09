module Htk
  class HTKHMMMixtureSet
    attr_accessor :name,:mixtures

    def initialize(ex_feature_space_dimension,ex_name=nil)
      @name=ex_name
      @mixtures = []
      @feature_space_dimension = ex_feature_space_dimension
    end

    def is_symbolic?
      return true if @mixtures.size == 0 and @name != nil
      false
    end

    def [](val)
      @mixtures[val]
    end

    def clear_mixtures
      @mixtures.clear
    end

    def add_basic_mixture(mix_probability=1.0)
      @mixtures.push HTKHMMMixture.new(@mixtures.size+1,mix_probability,@feature_space_dimension)
    end

    def add_formed_mixture(mixture)
      @mixtures.push mixture
    end

    def add_detailed_mixture(mix_probability,mean,variance,gconst=nil)
      tmp= HTKHMMMixture.new(@mixtures.size+1,mix_probability,@feature_space_dimension)
      tmp.mean = mean
      tmp.variance = variance
      tmp.gconst = gconst
      @mixtures.push tmp
    end

    def set_probability_distribution(ex_mean,ex_variance,ex_gconst)
      @mixtures.each do |mix|
        mix.mean = ex_mean
        mix.variance = ex_variance
        mix.gconst = ex_gconst
      end
    end

    def symbolic_to_s
      return "~s \"#{@name}\" \n" if @name != nil
      ""
    end

    def to_s
      return  symbolic_to_s if is_symbolic?
      symbolic_to_s + mixture_number_to_s + mixtures_to_s
    end

    def mixture_number_to_s
      return "" if @mixtures.size == 1
      "<NUMMIXES> #{@mixtures.size}\n"
    end

    def mixtures_to_s
      return @mixtures[0].simple_to_s if @mixtures.size == 1
      @mixtures.inject(""){|res,mix| res+=mix.full_to_s}
    end


    def HTKHMMMixtureSet.read_in_composition(file,ex_feature_space_dimension,name)
      set = HTKHMMMixtureSet.new(ex_feature_space_dimension,name)
      mixture_num = HTKHMMMixture.read(file,ex_feature_space_dimension)

      mixture_num.times do
          set.add_formed_mixture HTKHMMMixture.read(file,ex_feature_space_dimension)
      end

      return set
    end

    def HTKHMMMixtureSet.read(lines,ex_feature_space_dimension)
      name = HTKHMMMixtureSet.extract_symbolic_name(lines)
      set = HTKHMMMixtureSet.new(ex_feature_space_dimension,name)
      if not HTKHMMMixtureSet.is_just_symbolic_link(lines)
        num_mixtures = HTKHMMMixtureSet.extract_num_mixtures(lines)
        mixtures = HTKHMMMixtureSet.extract_mixtures(lines,num_mixtures,ex_feature_space_dimension)
        set.mixtures=mixtures
      end
      return set
    end

    def HTKHMMMixtureSet.extract_mixtures(lines,num_mixtures,feature_space_dim)
      old = -1
      current = -1
      mixtures = []

      if num_mixtures == 1
        mixtures.push HTKHMMMixture.read(lines,feature_space_dim)
      else
        lines.each_with_index do |line,index|
          if HTKHMMMixture.is_mixture_line?(line) or index == lines.size-1
            old = current
            current = index
          end
          if old != -1 and current !=-1
            mixtures.push HTKHMMMixture.read(lines[old...current],feature_space_dim)
            old = -1
          end
        end
      end

      raise "Less mixtures found than indicated in the model" if mixtures.size != num_mixtures
      return mixtures

    end


    def HTKHMMMixtureSet.extract_num_mixtures(lines)
      lines.each do |line|
        return HTKHMMMixtureSet.extract_num_mixtures_value(line) if HTKHMMMixtureSet.is_num_mixtures_line?(line)
      end
      return 1
    end

    def HTKHMMMixtureSet.is_num_mixtures_line?(line)
      line =~ /<NUMMIXES>/
    end

    def HTKHMMMixtureSet.extract_num_mixtures_value(line)
      line.split[1].to_i
    end

    def HTKHMMMixtureSet.extract_symbolic_name(lines)
      lines.each do |line|
        return HTKHMMMixtureSet.extract_symbolic_name_value(line) if HTKHMMMixtureSet.is_symbolic_name_line?(line)
      end
      return nil
    end

    def HTKHMMMixtureSet.is_symbolic_name_line?(line)
      line =~ /~s/
    end

    def HTKHMMMixtureSet.extract_symbolic_name_value(line)
      line.split[1].delete "\""
    end

    def HTKHMMMixtureSet.is_just_symbolic_link(lines)
      return true if lines.size == 1 and HTKHMMMixtureSet.is_symbolic_name_line?(lines[0])
    end


  end
end