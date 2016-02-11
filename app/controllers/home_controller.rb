class HomeController < ApplicationController
  layout "landing"

  skip_before_filter :verify_auth_user
  skip_before_filter :load_account_data

  def home
    @version = params[:version].to_s.downcase
    template = 'home/home'

    render template: template, layout: 'landing_25'
  end

  def index
  	if auth_user
		  return redirect_to :users_dashboard
    else
	    #render :index
      return redirect_to new_user_session_path
    end
  end

  def terms
    @page_title_prefix = 'Terms of Service - '
  end

  def privacy
    @page_title_prefix = 'Privacy - '
  end

  def privacy_and_terms
    @page_title_prefix = 'Privacy and Terms of Service - '
  end

  def safety
    @page_title_prefix = 'Safety - '
    params[:hide_navbar] = true
    render layout: 'landing_25'
  end

  def about_us
    @page_title_prefix = 'About Us - '
    params[:hide_navbar] = true
    render layout: 'landing_25'
  end

  def faq
    @page_title_prefix = 'Frequently Asked Questions - '

    @question_answers = ::QuestionAnswer.order('order_index asc').to_a

    respond_to do|format|
      format.html do
        params[:hide_navbar] = true
        render layout: 'landing_25'
      end
      format.json { render json: @question_answers  }
    end
  end

end