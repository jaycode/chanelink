# controller to handle all member related
class MembersController < ApplicationController

  load_and_authorize_resource

  layout 'no_left_menu'
  before_filter :member_authenticate, :except => [:prompt_password, :prompt_password_set]

  # render form for new member
  def new
    @member = Member.new
    # set the initial data for member
    @member.role = MemberRole.general_role
    @member.account = current_member.account
  end

  # render edit form for member
  def edit
    @member = Member.find(params[:id])
    assigned_properties = Array.new
    MemberPropertyAccess.find_all_by_member_id(@member.id).each do |pa|
      assigned_properties << pa.property_id.to_s
    end
    @member.assigned_properties = assigned_properties
  end

  # handle member creation
  def create
    # initiate member object
    @member = Member.new(params[:member])
    @member.account = current_member.account
    @member.disabled = params[:member][:enabled] == 'on' ? false : true
    @member.skip_password_validation = true

    # check if email already exist but deleted
    if !@member.email.blank? and !Member.unscoped.find_by_email_and_deleted(@member.email, true).blank?
      existing = Member.unscoped.find_by_email_and_deleted(@member.email, true)
      flash.now[:notice] = t('members.create.message.email_exist', :email => @member.email, :undelete => ActionController::Base.helpers.link_to(t('general.click_here'), undelete_member_path(existing)))
      render 'new'
    elsif @member.valid?
      @member.save
      # save all the properties assigned for this member
      if !@member.assigned_properties.blank?
        @member.assigned_properties.each do |prop_id|
          prop = Property.active_only.find(prop_id)
          if prop.account == current_member.account
            MemberPropertyAccess.create(:member_id => @member.id, :property_id => prop.id)
          end
        end
      end

      flash[:notice] = t('members.create.message.success')
      redirect_to members_path
    else
      put_model_errors_to_flash(@member.errors)
      render 'new'
    end
  end

  # handler to receive member update
  def update
    # save the new value to a member object
    @member = Member.find(params[:id])
    @member.attributes = params[:member]
    @member.skip_password_validation = true
    @member.disabled = @member.enabled ? false : true
    @member.disabled = false if @member.super_member?

    if @member.valid?
      
      @member.save

      # if member becomes super then remove all property access
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
      redirect_to members_path
    else
      put_model_errors_to_flash(@member.errors)
      render 'edit'
    end
  end

  # render password change form
  def prompt_password
    @member = current_member
  end

  # Commit password change
  def prompt_password_set
    @member = current_member

    # get all the form value
    new_password = params[:new_password]
    new_password_confirmation = params[:new_password_confirmation]

    # validation check from the input form
    if new_password.blank?
      flash.now[:alert] = t('members.prompt_password.message.new_password_not_given')
      render :action => 'prompt_password'
    elsif new_password != new_password_confirmation
      flash.now[:alert] = t('members.prompt_password.message.new_password_does_not_match_confirmation')
      render :action => 'prompt_password'
    else
      # try set the new password and commit to repository
      # if fail then go to edit view again

      @member.password = new_password
      @member.skip_properties_validation = true
      if Member.valid_attribute?(:password, new_password)
        @member.update_attributes(:password => new_password, :prompt_password_change => false)
        puts @member.errors
        redirect_to dashboard_path
      else
        flash.now[:alert] = t("members.prompt_password.message.failure")
        render :action => 'prompt_password'
      end
    end
  end

  # do delete member
  def delete
    @member = Member.find(params[:id])

    if !@member.master?
      @member.update_attribute(:deleted, true)
      flash[:notice] = t("members.delete.message.success")
    else
      flash[:alert] = t("members.delete.message.can_not_delete_master")
    end
    redirect_to members_path
  end

  # undelete member
  def undelete
    @member = Member.unscoped.find(params[:id])
    @member.update_attribute(:deleted, false)
    flash[:notice] = t("members.undelete.message.success")
    redirect_to members_path
  end

end
