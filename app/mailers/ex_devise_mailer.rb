class ExDeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views

  def reset_password_instructions(record, token, opts={})
    #find the user
    user = User.with_reset_password_token(token)
    if user.should_contact_parent?
      opts[:to] = user.parent.email
    end
    super
  end
end
