module Htk
  class HTKHMMMixture
    attr_reader :id
    attr_accessor :mix_probability, :mean , :variance, :gconst
    def initialize(ex_id,ex_mix_probability,ex_feature_space_dimension)
      @id = ex_id
      @mix_probability = ex_mix_probability
      @feature_space_dimension = ex_feature_space_dimension
      @mean = Array.new(@feature_space_dimension,0.0)
      @variance = Array.new(@feature_space_dimension,1.0)
      @gconst = nil
    end
    def full_to_s
      header_to_s + mean_to_s + variance_to_s + gconst_to_s
    end

    def simple_to_s
      mean_to_s + variance_to_s + gconst_to_s
    end

    def header_to_s
      "<MIXTURE> #{@id} #{@mix_probability}\n"
    end

    def mean_to_s
      @mean.inject("<MEAN> #{@feature_space_dimension}\n"){|res,val| res+= "#{val.to_s} "}+"\n"
    end

    def variance_to_s
      @variance.inject("<VARIANCE> #{@feature_space_dimension}\n"){|res,val| res+= "#{val.to_s} "}+"\n"
    end

    def gconst_to_s
      return "<GCONST> #{@gconst} \n" unless @gconst.nil?
      ""
    end

    def HTKHMMMixture.read(lines,ex_feature_space_dimension)
      state_status = :init
      num_values = -1
      mixture = nil
      lines.each do |line|
        if is_mixture_line? line
          current_mixture = extract_mixture_id(line)
          mix_probability = extract_mixture_probability line
          mixture = HTKHMMMixture.new(current_mixture,mix_probability,ex_feature_space_dimension)
          state_status = :read_mixture
        elsif is_state_mean_line? line and (state_status == :init or state_status == :read_mixture)
          num_values = extract_state_mean line
          state_status = :mean_header
        elsif state_status == :mean_header
          mixture = HTKHMMMixture.new(0,1.0,ex_feature_space_dimension) if mixture.nil?
          mixture.mean = extract_values(line,num_values)
          state_status = :read_mean
        elsif is_state_variance_line? line and state_status == :read_mean
          num_values = extract_state_variance line
          state_status = :variance_header
        elsif state_status == :variance_header
          mixture.variance = extract_values(line,num_values)
          state_status = :read_variance
        elsif is_state_gconst_line? line  and state_status == :read_variance
          mixture.gconst= extract_gconst line
        end
      end

      return mixture
    end

    def HTKHMMMixture.is_mixture_line?(line)
      line =~ /<MIXTURE>/
    end

    def HTKHMMMixture.extract_mixture_id(line)
      line.split[1].to_i
    end

    def HTKHMMMixture.extract_mixture_probability(line)
      line.split[2].to_f
    end


    def HTKHMMMixture.is_state_variance_line?(line)
      line =~ /<VARIANCE>/
    end

    def HTKHMMMixture.extract_state_variance(line)
      line.split[1].to_i
    end

    def HTKHMMMixture.is_state_mean_line?(line)
      line =~ /<MEAN>/
    end

    def HTKHMMMixture.extract_state_mean(line)
      line.split[1].to_i
    end

    def HTKHMMMixture.extract_values(line,num_values)
      values = line.split
      raise "incorrect number of values found" if values.size != num_values
      values.map{|value| value.to_f}
    end

    def HTKHMMMixture.is_state_gconst_line?(line)
      line =~ /<GCONST>/
    end

    def HTKHMMMixture.extract_gconst(line)
      line.split[1].to_f
    end


  end
end