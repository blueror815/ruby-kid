class QuestionAnswersController < InheritedResources::Base

  respond_to :js, only: [:destroy]

  before_filter :verify_admin!, except: [:show, :index]


  def index
    if auth_user.is_a?(Admin)
      @page_title = 'Frequently Asked Questions and Answers'

      @question_answers = ::QuestionAnswer.order('order_index asc')

      respond_to do|format|
        format.html
      end
    else
      redirect_to faq_path
    end
  end

  # Batch update of order_index.
  def update_all

    params.each_pair do|k, v|
      if k.to_s =~ /^mapping_(\d+)$/
        cc_id = $1.to_i
        logger.info "| Mapping #{cc_id}: #{v.inspect}"
        ::QuestionAnswer.update(cc_id, v)
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


end