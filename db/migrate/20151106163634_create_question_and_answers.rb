class CreateQuestionAndAnswers < ActiveRecord::Migration
  def up

    create_table_unless_exists :question_answers do|t|
      t.text :question, null: false
      t.text :answer
      t.integer :created_by_user_id
      t.integer :answered_by_user_id
      t.integer :order_index, default: 0
      t.timestamps
    end

    add_index_unless_exists :question_answers, :order_index
    add_index_unless_exists :question_answers, :created_at

    if ::QuestionAnswer.count == 0
      ::QuestionAnswer.populate_from_yaml_file
    end
  end

  def down
    drop_table_if_exists :question_answers
  end
end
