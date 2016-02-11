module Users
  class Permission < ActiveRecord::Base

    self.table_name = 'permissions'
  
    FLAGS = [
      EditItem=2, ManageItem=4, SuspendItem=8, ViewItemOutside=16,
      Comment=2**5, Trade=2**6, Buy=2**7, FinalizeTrade=2**8,
      RateTransaction=2**13,
      FollowUser=2**20
    ]
  
    
    belongs_to :user
    belongs_to :secondary_user, class_name: 'User'
    
  end
end