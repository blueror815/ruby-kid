module Users
  class FriendRequestController < ApplicationController

    include ::Users::UserInfo

    before_filter :get_current_friend_request, :only => [:show, :deny_request, :accept]
    before_filter :check_api_version, only: [:show, :create, :accept, :deny_request]
    before_filter :check_user_eligibility, only: [:show, :create, :accept, :deny_request]

    def index
      #takes the auth_user request + params[expand_search], params[:query]
      expanded_search = params[:expand_search].to_s != 'false'
      if params[:query].present?
        search = User.search_possible_friends(params[:query].downcase, auth_user, expanded_search)
        results = search.results
      else
        results = []
      end
      if results.empty?
        respond_to do |format|
          format.json {
            render json: {
                       users: []
                   }
          }
        end
      else
        respond_to do |format|
          format.json {
            render json: {
                       users: with_location(results, expanded_search)
                   }
          }
        end
      end
    end

    def create
      #auth user will send a request
      #expect a params[:comment] with the comment
      test_results = ::Users::FriendRequest.where(recipient_user_id: params[:requested], requester_user_id: auth_user.id)
      if test_results.empty?
        friend_request = ::Users::FriendRequest.new(recipient_user_id: params[:requested], requester_user_id: auth_user.id,
                                                    requester_message: params[:message])
        friend_request.requires_parent_approval = (@api_version == 1)
        save_status = friend_request.save
        respond_to do |format|
          format.json {
            render json:{ success: save_status, duplicate: false }
          }
        end

      else
        #it's not empty. Let's check the state of that.
        check = test_results.last
        check.requires_parent_approval = (@api_version == 1)
        if check.requires_parent_approval == false
          check.save
        elsif check.status.eql? :sent_request_parent and check.updated_at < 1.day.ago
          check.create_notification_mail!
          check.save

        elsif check.status.eql? :accept_recip_child and check.updated_at < 1.day.ago
          check.create_notification_mail!
          check.save
        end
        respond_to do |format|
          format.json { render json: { success: false, duplicate: true } }
        end
      end
    rescue ActiveRecord::RecordNotUnique
      #this will only occur when they try to save and the other friend has already sent them an FR
      respond_to do |format|
        format.json { render json: {  success: true, duplicate: true } }
      end
    end

    def accept
      if @friend_request.accept(auth_user.id, params[:message])
        respond_to do |format|
          format.json {
            render json: {
                       success: true
                   }
          }
          format.html { render template:'users/friend_requests/approve_confirmed' }
        end
      else
        respond_to do |format|
          format.json {
            render json: {
                       success: false
                   }
          }
          format.html { redirect_to action:'show', t: Time.now.to_i }
        end
      end
    end

    def deny_request
      if @friend_request.recipient_user_id.eql? auth_user.id or
          @friend_request.requester_parent_id.eql? auth_user.id or
          @friend_request.recipient_parent_id.eql? auth_user.id

        @friend_request.status = :denied
        ::Users::Notification.where(related_model_type: "::Users::FriendRequest", related_model_id: @friend_request.id).delete_all
        if @friend_request.save
          respond_to do |format|
            format.json {
              render json: {
                         success: true
                     }
            }
            format.html { redirect_to notifications_path }
          end
        else
          respond_to do |format|
            format.json {
              render json: {
                         success: false
                     }
            }
            format.html { redirect_to action:'show', t: Time.now.to_i }
          end
        end
      else
        respond_to do |format|
          format.json {
            render json: {
                       success: false
                   }
          }
        end
      end
    end

    def show
      @page_title = 'Friend Request'
      #show will be called by both parents and kid. auth user will be here.
      #load friend request and check fi the requesting user is authorized to use it.
      respond_to do |format|
        format.json {
          render json: @friend_request.as_json(auth_user.id)
        }
        format.html { render template:'users/friend_requests/show' }
      end
    end

    ##############################

    protected

    def get_current_friend_request
      @friend_request = ::Users::FriendRequest.find_by_id(params[:id])
      if @friend_request.nil?
        respond_to do|format|
          format.json { render( status: 404, json: make_json_status_hash(false) ) && return }
          format.html { redirect_to '/404' }
        end
      end
    end

    ##
    # Only for API calls like /api/v%{api_version}/xxxxxxx.  Also, params[:api_version] would override this in URL.
    # Then sets the @api_version.
    def check_api_version
      if request.path =~ /^\/api\/v(\d+)\//
        @api_version = 2 # $1.to_i # no longer needed
      end
      @api_version = params[:api_version].to_i if params[:api_version]
      if @api_version && @friend_request
        @friend_request.requires_parent_approval = (@api_version.to_i == 1 )
      end
    end

    def check_user_eligibility
      result_h = check_eligibility(auth_user)
      unless result_h[:result]
        flash[:error] = result_h[:error]
        flash[:reason] = result_h[:reason]
        logger.info "| Errors: #{flash[:error]}"
        logger.info "| Reason: #{flash[:reason]}"
        respond_to do |format|
          format.json { render json: make_json_status_hash(false, false) }
          format.html { redirect_to '/422' }
        end
      end
    end

    def with_location(users, expand_search)
      result = []
      if expand_search
        users.each do |user|
          to_json = user.as_json.merge({'city' => user.city.strip.titleize, 'state' => user.state})
          to_json['current_school_name'] = ''
          result << to_json
        end
      else
        users.each do |user|
          to_json = user.as_json.merge({'city' => '', 'state' => ''})
          result << to_json
        end
      end
      return result
    end

  end
end
