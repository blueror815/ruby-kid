module Users
  class BoundariesController < ApplicationController

    before_filter :find_user

    def index
      @page_title = @menu_title = 'Boundaries'

      @boundaries = @user.boundaries

      @categories = Category.for_user(@user)

      respond_to do |format|
        format.json { render json: @boundaries }
        format.html
      end
    end

    ##
    # For now, erases ALL boundaries of the user.  Maybe in future would only erase these modified boundary types.
    # parameters:
    #   :child_circle_option <String, one of those in ::Users::ChildCircleOption::CIRCLE_OPTIONS_MAP.keys>
    #   :block_user_ids <Array of all strings or all integers>
    #   :block_keywords <Array of strings or comma-separated string>
    #   :block_category_ids <Array of integer>
    def update

      @boundaries = []

      ( params[:block_category_ids] || [] ).each do|category_id|
        @boundaries << ::Users::CategoryBlock.new(user_id: @user.id, content_type_id: category_id )
      end

      child_circle_option = params[:child_circle_option]
      if child_circle_option.present? && ::Users::ChildCircleOption::CIRCLE_OPTIONS_MAP.keys.include?(child_circle_option)
        @boundaries << ::Users::ChildCircleOption.new(user_id: @user.id, content_keyword: child_circle_option)
      end

      if ( keywords = params[:block_keywords] ).present?
        (keywords.is_a?(Array) ? keywords : keywords.split(/,\s*/) ).each do|kw|
          @boundaries << ::Users::KeywordBlock.new(user_id: @user.id, content_keyword: kw)
        end
      end

      if ( block_user_ids = params[:block_user_ids]).present?
        user_ids = block_user_ids.split(/,\s*/)
        if user_ids.first.is_a?(String) && user_ids.first =~ /^\D+\S+/
          user_ids = ::User.where(user_name: user_ids ).select('id').to_a.collect(&:id)
        end
        user_ids.each do|user_id|
          @boundaries << ::Users::UserBlock.new(user_id: @user.id, content_type_id: user_id)
        end
      end
      @user.boundaries = @user.boundaries + @boundaries
      @user.save

      respond_to do |format|
        format.json { render json: @boundaries }
        format.html { redirect_to(boundaries_path) }
      end

    end

    protected

    def find_user
      @user = params[:id] ? ::User.find_by_id(params[:id]) : auth_user
      if @user
        check_permission(@user)
      else
        flash[:error] = "The requested user cannot be found"
        respond_to do|format|
          format.html { redirect_to(users_dashboard_path) }
          format.json { render json: {:error => flash[:error] }  }
        end
      end
    end

    def check_permission(user)
      if auth_user.nil? || (auth_user.id != user.id && !auth_user.parent_of?(user) )
        flash[:error] = "You do not have permission to access this."
      end

      if flash[:error].present?
        respond_to do |format|
          format.json { render( status: 401, json: make_json_status_hash(false) ) && return }
          format.html { redirect_back(users_dashboard_path) && return }
        end
      end
    end

  end
end
