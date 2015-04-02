# admin user module
class Admin::UsersController < Admin::AdminController

  load_and_authorize_resource

  layout 'admin/layouts/no_left_menu'

  before_filter :user_authenticate

  # ask for password change menu
  def prompt_password
    puts 'dsds'
    @user = current_user
  end

  # Commit password change
  def prompt_password_set
    @user = current_user

    # get all the form value
    new_password = params[:new_password]
    new_password_confirmation = params[:new_password_confirmation]

    # validation check from the input form
    if new_password.blank?
      flash.now[:alert] = t('admin.users.prompt_password.message.new_password_not_given')
      render :action => 'prompt_password'
    elsif new_password != new_password_confirmation
      flash.now[:alert] = t('admin.users.prompt_password.message.new_password_does_not_match_confirmation')
      render :action => 'prompt_password'
    else
      # try set the new password and commit to repository
      # if fail then go to edit view again

      @user.password = new_password
      @user.skip_properties_validation = true
      if User.valid_attribute?(:password, new_password)
        @user.update_attributes(:password => new_password, :prompt_password_change => false)
        puts @user.errors
        redirect_to admin_dashboard_path
      else
        flash.now[:alert] = t("users.prompt_password.message.failure")
        render :action => 'prompt_password'
      end
    end
  end

  # new user
  def new
    @user = User.new
  end

  # edit user
  def edit
    @user = User.find(params[:id])
    assigned_properties = Array.new
    UserPropertyAccess.find_all_by_user_id(@user.id).each do |pa|
      assigned_properties << pa.property_id.to_s
    end
    @user.assigned_properties = assigned_properties
  end

  # create user
  def create
    @user = User.new(params[:user])
    @user.skip_password_validation = true
    puts @user.assigned_properties

    if @user.valid?
      @user.save

      # user save property access assigned to this user
      if !@user.assigned_properties.blank?
        @user.assigned_properties.each do |prop_id|
          prop = Property.find(prop_id)
          UserPropertyAccess.create(:user_id => @user.id, :property_id => prop.id)
        end
      end

      flash[:notice] = t('admin.users.create.message.success')
      redirect_to admin_users_path
    else
      put_model_errors_to_flash(@user.errors)
      render 'new'
    end
  end

  # update user
  def update
    @user = User.find(params[:id])
    @user.skip_password_validation = true
    
    if @user.update_attributes(params[:user])

      @user.save

      if @user.super?
        UserPropertyAccess.where(:user_id => @user.id).destroy_all
      else
        # add new access
        @user.assigned_properties.each do |prop_id|
          prop = Property.find(prop_id)
          if UserPropertyAccess.find_by_user_id_and_property_id(@user.id, prop.id).blank?
            UserPropertyAccess.create(:user_id => @user.id, :property_id => prop.id)
          end
        end

        # remove access
        UserPropertyAccess.find_all_by_user_id(@user.id).each do |mpa|
          if !@user.assigned_properties.include?(mpa.property_id.to_s)
            mpa.destroy
          end
        end
      end

      flash[:notice] = t('admin.users.update.message.success')
      redirect_to admin_users_path
    else
      put_model_errors_to_flash(@user.errors)
      render 'edit'
    end
  end

  # delete user
  def delete
    @user = User.find(params[:id])
    @user.update_attribute(:deleted, true)
    flash[:notice] = t("admin.users.delete.message.success")
    redirect_to admin_users_path
  end

end
