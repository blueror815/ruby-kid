class FundRaisersController < InheritedResources::Base
  respond_to :html
  respond_to :js, only: [:create]
  layout 'landing_25', only:[:new, :edit, :show]

  skip_before_filter :load_account_data
  before_filter :verify_admin!, except: [:new, :create]

  def new
    @page_title_prefix = 'Fund Raising - '
    @version = 'fundraising' # This distinguishes from home action for the header & footer.
    super
  end

  def create
    create! do|format|
      format.html { redirect_to "/fundraising?t=#{Time.now.to_i}" }
      format.js { render text:"alert('Created!');" }
    end
  end

end