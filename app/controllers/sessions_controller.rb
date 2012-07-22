class SessionsController < ApplicationController

  def create
    provider = params[:provider]
    provider_uid_field = "#{provider}_uid"
    provider_name_field = "#{provider}_name"
    omniauth = request.env["omniauth.auth"]

    user = User.where(provider_uid_field => omniauth['uid']).first

    origin = request.env['omniauth.origin']
    target = if origin == login_session_url
               records_path
             else
               origin || records_path
             end

    if user
      flash[:notice] = "Signed in successfully"
      session[:user_id] = user.id.to_s
      redirect_to target
    else
      user_info = omniauth['info']
      user = User.new(nickname: user_info['nickname'] || user_info['name'])

      user.update_attribute(provider_uid_field,  omniauth['uid'])
      user.update_attribute(provider_name_field, user_info['nickname'] || user_info['name'])

      user.update_attribute('email',   user_info['email'])
      user.update_attribute('about',   user_info['description'])
      user.update_attribute('website', user_info['urls'].try(:values).try(:last))

      if user.save
        session[:user_id] = user.id.to_s
        flash[:notice] = "Signed in successfully"
        session[:return_to] = target
        redirect_to edit_user_path(user)
      else
        flash[:notice] = "Authentication failed"
        redirect_to root_url
      end
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path
  end

  def failure
    redirect_to root_path, :alert => 'Something went wrong while trying to log you in.'
  end
end
