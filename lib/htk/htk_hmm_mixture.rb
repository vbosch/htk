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

  end
end