class AddIndexToRelatedModelType < ActiveRecord::Migration
  def change
    add_index_unless_exists :notifications, :related_model_type
  end
end
