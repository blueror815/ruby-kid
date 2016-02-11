class CreateReports < ActiveRecord::Migration
  def up

    create_table_unless_exists :reports do|t|
      t.integer :offender_user_id, null: false
      t.integer :reporter_user_id, null: false
      t.integer :resolver_user_id
      t.string  :content_type, null: false, length: 56
      t.integer :content_type_id, null: false
      t.string  :reason_type, length: 56
      t.text    :reason_message
      t.string  :status, length: 127
      t.integer :secondary_filter_severity
      t.boolean :resolved, default: false
      t.integer :resolution_level
      t.timestamps
      t.time    :resolved_at
    end
    add_index_unless_exists :reports, :offender_user_id
    add_index_unless_exists :reports, :reporter_user_id
    add_index_unless_exists :reports, :resolver_user_id
    add_index_unless_exists :reports, [:content_type, :content_type_id]
    add_index_unless_exists :reports, :status
    add_index_unless_exists :reports, :resolved

    ##
    # Block Items
    create_table_unless_exists :item_blocks do|t|
      t.integer :blocker_user_id, null: false
      t.integer :item_id, null: false
      t.timestamps
    end
    add_index_unless_exists :item_blocks, :blocker_user_id
    add_index_unless_exists :item_blocks, :item_id

    # Block Users
    create_table_unless_exists :user_blocks do|t|
      t.integer :blocker_user_id, null: false
      t.integer :object_user_id, null: false
      t.timestamps
    end
    add_index_unless_exists :user_blocks, :blocker_user_id
    add_index_unless_exists :user_blocks, :object_user_id

    # Secondary Filter
    create_table_unless_exists :secondary_filter_keywords do|t|
      t.string :keyword, length: 56
      t.integer :severity
    end

    add_column_unless_exists :users, :reported_count, :integer, default: 0
    add_column_unless_exists :users, :reporter_count, :integer, default: 0
    add_column_unless_exists :users, :banned, :boolean, default: false
  end

  def down
    drop_table_if_exists :reports
    drop_table_if_exists :item_blocks
    drop_table_if_exists :user_blocks
    drop_table_if_exists :secondary_filter_keywords
  end
end
