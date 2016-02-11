class AddIndexToReportsResolved < ActiveRecord::Migration
  def change

    add_index_unless_exists :reports, :resolved
  end
end
