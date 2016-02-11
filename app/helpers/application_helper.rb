module ApplicationHelper

  def auth_user
    current_user
  end

  def display_error_on(record, attribute_key, &block)
    if record && record.errors.present? && (msg = record.errors.messages[attribute_key.to_sym]).present?
      yield msg.collect(&:humanize).join('. ')
    end
  end

  def back_page_url
    uri = session[:original_uri].to_s
    if uri.present?
      uri << (uri.index('?') ? '&' : '?' ) + 'returning=1'
    end
    uri
  end

  # Is the page a public landing page
  def landing_page?
    path = request.path
    path == root_path || (params[:controller]=='stores' && params[:action]=='landing')
  end

  def pagination_links(collection, options = {})
    options[:renderer] ||= Bootstrap::LinkRenderer
    options[:class] ||= 'pagination'
    options[:inner_window] ||= 2
    options[:outer_window] ||= 1
    will_paginate(collection, options)
  end

  # options
  #   :user_info_level <symbol> either :public or :known and default :public.
  
  def user_profile_link(user, options = {}, html_options = {}, &block)
    link_to(options[:user_info_level]==:known ? known_user_id(user) : public_user_id(user), 
            "/profiles/#{user.id}", {title: user.user_name}.merge(html_options), &block)
  end

  ##
  # Used to be that More 'hamburger' icon leading to user dashboard.
  def auth_user_more_icon(user = nil)
    user ||= auth_user
    if user.is_a?(Parent)
      image_tag('/assets/icons/mom@2x.png', alt: 'Dashboard', title: 'Dashboard')
    else
      image_tag(user.profile_image_url(:thumb), class:'user-avatar-icon', alt: "#{user.display_name}", title: "#{user.display_name}")
    end
  end


  # Those who have been in discussion with, so would include short name.
  def known_user_id(user)
    user.display_name
  end

  def public_user_id(user)
    user.user_name
  end
  
  def within_cubbyshop?
    logger.info "  Request.host = #{request.host}"
    request.host =~ /cubbyshop\.com$/ || request.host =~ /localhost$/
  end

  ##
  # Either Cubby Shop or Kids Trade
  def domain_name
    session['domain_name'] ||= (request.host =~ /cubbyshop\.com$/) ? 'Cubby Shop' : 'Kids Trade'
  end

  def login_requires_email_only?(request)
    ( request.format != 'application/json' && ( !Rails.env.test? || Rails.env.development? ) )
  end
end
