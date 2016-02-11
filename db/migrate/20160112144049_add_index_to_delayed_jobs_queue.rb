class AddIndexToDelayedJobsQueue < ActiveRecord::Migration
  def change
    change_column :delayed_jobs, :queue, :string, length: 191
    add_index_unless_exists :delayed_jobs, :queue
  end
end
