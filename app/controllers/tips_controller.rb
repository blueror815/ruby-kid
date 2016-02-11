class TipsController < InheritedResources::Base

  respond_to :js, only: [:create, :update, :update_all, :destroy]

  skip_before_filter :load_account_data
  before_filter :verify_admin!, except: [:index]

  def index
    @page_title_prefix = 'Tips - '

    @tips = ::Tip.order('order_index')
    respond_to do|format|
      format.json { render json: @tips.collect(&:title) }
      format.html do
        if auth_user.is_a?(Admin)
          render template: 'tips/admin', layout: 'application'
        else
          render layout: 'landing'
        end
      end
    end
  end

  def create
    super location: tips_path(t: Time.now.to_i)

  end

  # Batch update of order_index.
  def update_all

    params.each_pair do|k, v|
      if k.to_s =~ /^mapping_(\d+)$/
        cc_id = $1.to_i
        logger.info "| Mapping #{cc_id}: #{v.inspect}"
        ::Tip.update(cc_id, v)
      end
    end

    respond_to do|format|
      format.js { render :nothing => true }
      format.html { redirect_to action:'index' }
    end
  end

  protected

  def resource
    ['update_all'].include?(params[:action].to_s) ? nil : super
  end

  def verify_auth_user
    if request.format == 'application/json'
      super
    elsif params[:action].to_s != 'index'
      super
    end
  end
end

