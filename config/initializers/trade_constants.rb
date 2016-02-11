module TradeConstants

  REQUIRES_PARENT_APPROVAL_FOR_UNEVEN_TRADE = false

  #better deal coefficient. If the buyer's items is worth 1.7 times less than the beta's item, a warning occurs.
  ALPHA_COEFF = 10000.0 # 1.7
  #higher threshold means different warning to alpha user.
  ALPHA_PRIME_COEFF = 10000.0 # 1.75
  #parent approval is required for the above coefficient.
  ALPHA_APPROVAL_REQUIRED = 10000.0 # 1.75
  #warning is displayed if the person getting the shorter end of the stick has an item that's worth .7 times more than the other person's item
  BETA_COEFF = 0.0000001 # 0.7
  #lower threshold for a worse trade, and a different message is displayed.
  BETA_PRIME_COEFF = 0.0000001 # 0.4
  #parent approval is required for a trade that matched this criteria.
  BETA_APPROVAL_REQUIRED = 0.0000001 # 0.5
  #minimum number of items for a user to make a trade
  ITEMS_MIN_THRESHOLD = 1.0
  #minimum number of items for a new user to make their first trade
  NEW_USER_ITEMS_MIN_THRESHOLD = 1.0
  #number of items where a user is warned for having too few items.
  ITEMS_LOW_WARNING_THRESHOLD = 1.0

  PARENT_APPROVAL_HIGH_PRICE_THRESHOLD = 10000000.0 # 50.0

  NO_PARENT_APPROVE = 10.0

  MIN_FIRST_TIME_PHOTOS = 8.0
end
