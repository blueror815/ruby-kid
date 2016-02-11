class ReportsController < ApplicationController

  before_filter :find_current_report, only: [:show, :update, :destroy, :repost ]

  def new
    @report = ::Report.new(params[:report])
    set_content_attributes!(@report)
    
    set_referer_as_redirect_back
    
    respond_to do|format|
      format.html
    end
  end

  def show
    respond_to do|format|
      format.json { render json: @report }
      format.html
    end
  end

  def create
    params[:content_type] = params[:type] if params[:type].present?
    @report = ::Report.new(params[:report] || params.select{|k,v| [:content_type, :content_type_id, :reason_type, :reason_message].include?(k.to_sym) } )
    @report.reporter_user_id = auth_user.id
    
    set_content_attributes!(@report)
    
    respond_to do |format|
      if @report.save
        format.html { redirect_back(action: 'index') }
        format.json { render json: { report: @report, success: true } }
      else
        set_flash_messages_from_errors(@report)
        format.html { render action: 'edit' }
        format.json { render json: { error: @report.errors.first.join(' ') } }
      end
    end
  end

  ##
  # Repost for user and approve for admin.
  # For admin approval, can be given params[:report] hash with :resolution_level
  def repost
    success = @report.repost_by!(auth_user, params[:report] )
    respond_to do|format|
      format.json { render json: { report: @report, success: success } }
      format.html { redirect_back(action: 'index') }
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.json { render json: { error: @report.errors.first.join(' ') }, status: :unprocessable_entity }
    end
  end

  def update
    @report.attributes = params[:report] || {}
    @report.save
    respond_to do|format|
      format.html { redirect_back(action: 'index') }
      format.json { render json: { report: @report, success: true } }
    end
  end

  def destroy

    success = @report.delete_by!(auth_user, params[:report] )
    respond_to do|format|
      format.html { redirect_back(action: 'index') }
      format.json { render json: { report: @report, success: success } }
    end
  end

  def index
    if auth_user.is_a?(Admin)
      @reports = ::Report.where(resolved: false).order('id asc')
    else
      @reports = ::Report.for_user(auth_user)
    end
    respond_to do|format|
      format.html
      format.json { render json: @reports }
    end
  end


  private

  def find_current_report
    @report = ::Report.find_by_id(params[:id])
    if @report
      check_permission(@report)
    else
      flash[:error] = "The requested report cannot be found"
      respond_to do|format|
        format.html { redirect_to(reports_path) }
        format.json { render json: {:error => flash[:error] }  }
      end
    end
  end
  
  ##
  # Other than having params[:report][:content_type] and params[:report][:content_type_id] set, there can be type-specific
  # ID parameter set like item_id=105, and same for item_comment_id and trade_comment_id.  This can set content_type,
  # content_type_id, and offender_user_id attributes of report.
  def set_content_attributes!(report)
    if report.content_type.blank? && report.content_type_id.to_i == 0
      if (item_id = params[:item_id] || params[:report].try(:[], :item_id) ).to_i > 0
        report.content_type = 'ITEM'
        report.content_type_id = item_id
      elsif (item_comment_id = params[:item_comment_id] || params[:report].try(:[], :item_comment_id) ).to_i > 0
        report.content_type = 'ITEM_COMMENT'
        report.content_type_id = item_comment_id
      elsif (trade_comment_id = params[:trade_comment_id] || params[:report].try(:[], :trade_comment_id) ).to_i > 0
        report.content_type = 'TRADE_COMMENT'
        report.content_type_id = trade_comment_id
      end
    end
    if ::Report.valid_content_type?(report.content_type)
      if (record = report.content_record)
        report.offender_user_id ||= record.user_id # this assumes all types have user_id as the offender.
      else
        flash[:error] = "The reported record cannot be found"
      end
    end
  end

  def check_permission(report)
    if report
      if report.viewable_by_user?(auth_user) == false
        flash[:error] = "You do not have permission to access this report."
      elsif params[:action] == 'repost'
        flash[:error] = "You do not have permission to repost this #{report.content_type.humanize.downcase}." if report.repostable_by_user?(auth_user) == false
      elsif params[:action] == 'delete'
        flash[:error] = "You do not have permission to delete this #{report.content_type.humanize.downcase}." if report.deleteable_by_user?(auth_user) == false
      elsif params[:action] == 'update'
        flash[:error] = "You do not have permission to access this report."
      end
    end

    if flash[:error].present?
      respond_to do |format|
        format.json { render( status: 401, json: make_json_status_hash(false) ) && return }
        format.html { redirect_back(reports_path) && return }
      end
    end
  end
  
end
