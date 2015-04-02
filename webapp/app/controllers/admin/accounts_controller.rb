# account module for back office
class Admin::AccountsController < Admin::AdminController

  layout 'admin/layouts/no_left_menu'

  # new account form
  def new
    session[:account_params] = {}
    session[:member_params] = {}
    redirect_to new_wizard_for_account_admin_accounts_path
  end

  # new account wizard - step 1
  def new_wizard_for_account
    @account = Account.new(session[:account_params])
  end

  # new account wizard - step 2
  def new_wizard_for_super_member

    init_variables_from_sessions
    
    if @account.valid?
      # do nothing
    else
      put_model_errors_to_flash(@account.errors, 'redirect')
      redirect_to new_wizard_for_account_admin_accounts_path
    end
  end

  # new account wizard - last step
  def create

    init_variables_from_sessions

    if params[:back_button]
      redirect_to new_wizard_for_account_admin_accounts_path
    else
      if !@super_member.valid?
        put_model_errors_to_flash(@super_member.errors, 'redirect')
        render 'new_wizard_for_super_member'
      elsif !@account.valid?
        put_model_errors_to_flash(@account.errors, 'redirect')
        redirect_to new_wizard_for_account_admin_accounts_path
      else
        # save both account and super member
        @account.save
        @super_member.account = @account
        @super_member.master = true
        @super_member.save
        redirect_to done_creating_admin_accounts_path(:account_id => @account.id)
      end
    end
  end

  # after create account
  def done_creating
    @account = Account.find(params[:account_id])
    @super_member = @account.super_members.first
  end

  # edit account
  def edit
    @account = Account.find(params[:id])
  end

  # update account
  def update
    @account = Account.find(params[:id])
    @account.disabled = params[:account][:enabled] == 'on' ? false : true

    if @account.update_attributes(params[:account])
      flash[:notice] = t('admin.accounts.update.message.success')
      redirect_to admin_setup_path
    else
      put_model_errors_to_flash(@account.errors)
      render :action => "edit"
    end
  end

  # delete account
  def delete
    @account = Account.find(params[:id])
    @account.update_attribute(:deleted, true)
    @account.properties.each do |prop|
      prop.update_attribute(:deleted, true)
    end
    flash[:notice] = t("admin.accounts.delete.message.success")
    redirect_to admin_setup_path
  end

  # activate account
  def activate
    @account = Account.find(params[:id])

    # requirement for activating an account
    if @account.properties.count == 0
      flash[:alert] = t("admin.accounts.activate.message.no_property")
    elsif @account.properties.first.channels.count == 0
      flash[:alert] = t("admin.accounts.activate.message.no_channels")
    elsif @account.properties.first.room_types.count == 0
      flash[:alert] = t("admin.accounts.activate.message.no_room_type")
    elsif RoomTypeChannelMapping.room_type_ids(@account.properties.first.room_type_ids).count != (@account.properties.first.room_types.count * @account.properties.first.channels.count)
      flash[:alert] = t("admin.accounts.activate.message.no_room_type_channel_mapping")
    else
      @account.update_attribute(:approved, true)

      # send notification to users about property approval
      @account.properties.each do |p|
        PropertyChannelApprovedAlert.resend_email(p)
      end
      
      @account.members.each do |m|
        m.new_member_password
      end

      flash[:notice] = t("admin.accounts.activate.message.success")
    end
    redirect_to admin_setup_path
  end

  private

  # helper for new account wizard
  def init_variables_from_sessions
    session[:account_params].deep_merge!(params[:account]) if params[:account]
    session[:member_params].deep_merge!(params[:member]) if params[:member]
    @account = Account.new(session[:account_params])
    @super_member = Member.new(session[:member_params])
    @super_member.role = MemberRole.super_role
    @super_member.skip_password_validation = true
  end

end
