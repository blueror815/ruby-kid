module Users
  module UserInfo
    # This general rule represents actions a child taking with other children
    # such as trading
    REQUIRES_ACCOUNT_CONFIRMATION_FOR_INTERACTIONS = false
    
    object_constants :creation_error, :new_user_item_minimum, :shop_too_low, :account_not_confirmed, :incomplete_registration
    
    ##
    # @return <Hash of {result:<boolean>, error_code:<String>, error:<String>, reason:<String> }
    def check_eligibility(user)
      return {result: false} if user.nil?

      result = true
      h = {}
      if user.is_a?(Child)
        parent_confirmed = user.parent.try(:account_confirmed?) || false

        if user.requires_parental_guidance? && user.parent.nil?
          h[:error_code] = CreationError::INCOMPLETE_REGISTRATION
          h[:error] = ::I18n.t('trading.alert.incomplete_registration.subject')
          result = false

        elsif REQUIRES_ACCOUNT_CONFIRMATION_FOR_INTERACTIONS && !parent_confirmed
          h[:error_code] = CreationError::ACCOUNT_NOT_CONFIRMED
          h[:error] = ::I18n.t("trading.alert.account_not_confirmed.subject")
          h[:reason] = ""
          result = false

        end

      elsif user.is_a?(Parent)
        if user.account_confirmed?
          result = true
        else
          h[:error] = ::I18n.t("trading.alert.account_not_confirmed_parent.subject")
          h[:reason] = ::I18n.t("trading.alert.account_not_confirmed_parent.tip")
          result = false
        end

      end
      h[:result] = result
      h
    end

    ##
    # In addition to account-based checks in check_eligibility, checks against requirements to perform trade actions.
    # @return <Hash of {result:<boolean>, error_code:<String>, error:<String>, reason:<String> }
    def check_eligibility_for_trading(user)
      result = true
      h = check_eligibility(user)
      if h[:result] == false
        result = false

      elsif user.item_total.eql?(0)
        h[:error_code] = CreationError::SHOP_TOO_LOW
        h[:error] = ::I18n.t("trading.alert.zero_items.subject")
        h[:reason] = ::I18n.t("trading.alert.not_enough_items.tip", {item_count: ::TradeConstants::ITEMS_MIN_THRESHOLD.to_i })
        result = false

      elsif user.item_total < TradeConstants::ITEMS_MIN_THRESHOLD
        h[:error_code] = CreationError::SHOP_TOO_LOW
        h[:error] = ::I18n.t("trading.alert.not_enough_items.subject")
        h[:reason] = ::I18n.t("trading.alert.not_enough_items.tip", {item_count: ::TradeConstants::ITEMS_MIN_THRESHOLD.to_i })
        result = false

      end
      h[:result] = result
      h
    end
  end
end