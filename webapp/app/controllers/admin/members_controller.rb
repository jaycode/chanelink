# admin module to manage members
class Admin::MembersController < Admin::AdminController

  before_filter :user_authenticate_and_account_property_selected

  # create new member
  def new
    @member = Member.new
    @member.role = MemberRole.general_role
    @member.account = current_admin_property.account
  end

  # edit member
  def edit
    @member = Member.find(params[:id])
    assigned_properties = Array.new
    MemberPropertyAccess.find_all_by_member_id(@member.id).each do |pa|
      assigned_properties << pa.property_id.to_s
    end
    @member.assigned_properties = assigned_properties
  end

  # create member
  def create
    @member = Member.new(params[:member])
    @member.account = current_admin_property.account
    @member.disabled = params[:member][:enabled] == 'on' ? false : true
    @member.skip_password_validation = true

    # check if email never been used by deleted user
    if !@member.email.blank? and !Member.unscoped.find_by_email_and_deleted(@member.email, true).blank?
      existing = Member.unscoped.find_by_email_and_deleted(@member.email, true)
      flash.now[:notice] = t('members.create.message.email_exist', :email => @member.email, :undelete => ActionController::Base.helpers.link_to(t('general.click_here'), undelete_admin_member_path(existing)))
      render 'new'
    elsif @member.valid?
      @member.save

      # create properties access for this new member
      if !@member.assigned_properties.blank?
        @member.assigned_properties.each do |prop_id|
          prop = Property.active_only.find(prop_id)
          if prop.account == current_admin_property.account
            MemberPropertyAccess.create(:member_id => @member.id, :property_id => prop.id)
          end
        end
      end

      flash[:notice] = t('members.create.message.success')
      redirect_to admin_members_path
    else
      put_model_errors_to_flash(@member.errors)
      render 'new'
    end
  end

  # update member
  def update
    @member = Member.find(params[:id])
    @member.attributes = params[:member]
    @member.skip_password_validation = true
    @member.disabled = params[:member][:enabled] == 'on' ? false : true

    if @member.valid?
      
      @member.save

      # if member changed to super, delete all property access
      if @member.super_member?
        MemberPropertyAccess.where(:member_id => @member.id).destroy_all
      else
        # add new access
        @member.assigned_properties.each do |prop_id|
          prop = Property.active_only.find(prop_id)
          puts "#{prop} #{prop.account == @member.account} #{MemberPropertyAccess.find_by_member_id_and_property_id(@member.id, prop.id).blank?}"
          if prop.account == @member.account and MemberPropertyAccess.find_by_member_id_and_property_id(@member.id, prop.id).blank?
            MemberPropertyAccess.create(:member_id => @member.id, :property_id => prop.id)
          end
        end

        # remove access
        MemberPropertyAccess.find_all_by_member_id(@member.id).each do |mpa|
          if !@member.assigned_properties.include?(mpa.property_id.to_s)
            mpa.destroy
          end
        end
      end

      flash[:notice] = t('members.update.message.success')
      redirect_to admin_members_path
    else
      put_model_errors_to_flash(@member.errors)
      render 'edit'
    end
  end

  # delete member
  def delete
    @member = Member.find(params[:id])
    @member.update_attribute(:deleted, true)
    flash[:notice] = t("members.delete.message.success")
    redirect_to admin_members_path
  end

  # undelete member
  def undelete
    @member = Member.unscoped.find(params[:id])
    @member.update_attribute(:deleted, false)
    flash[:notice] = t("members.undelete.message.success")
    redirect_to admin_members_path
  end

end
