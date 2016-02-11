class QuestionAnswer < ActiveRecord::Base
  attr_accessible :question, :answer, :order_index

  before_create :set_defaults!


  def set_defaults!
    if self.order_index.nil?
      max_record = self.class.order('order_index desc').first
      self.order_index = max_record ? max_record.order_index + 1 : 1
    end
  end


  def self.populate_from_yaml_file
    h = YAML::load_file( File.join(Rails.root, 'doc/data/question_answers.yml') )
    list = h.is_a?(Array) ? h : h.values.first
    list.collect do|yml_record|
      create( yml_record.attributes )
    end
    puts "|- Loaded #{list.size} of the total #{count} Questions & Answers"
  end
end
