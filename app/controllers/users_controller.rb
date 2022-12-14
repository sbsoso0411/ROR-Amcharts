class UsersController < ApplicationController
    include JobAnalysisHelper
    before_filter :signed_in_user, only: [:index, :show, :settings, :update]
    before_filter :signed_in_support_role, only: [:new, :create, :destroy, :edit]
    set_tab :users

    def index
        respond_to do |format|
            format.html { @users = User.from_company(current_user.company).includes(:district, :company).paginate(page: params[:page], limit: 20) }
            format.js {
                if params[:search].length == 0
                    @users = User.from_company(current_user.company).where(:admin => false).paginate(page: params[:page], limit: 20)
                elsif params[:search].length > 1
                    @users = User.search(params, current_user.company).results
                end
            }
            format.json {
                if params[:q].present?
                    params[:search] = params[:q]
                end

                @users = User.search(params, current_user.company).results

                if @users.empty?
                    @users << User.new
                    render json: @users.map { |user| {:value => "No person found...", :name => "", :id => -1} }
                    return
                end

                if params[:q].present?
                    render json: @users.map { |user| {:name => user.name + " (" + user.title.to_s + " / " + user.district.name + ")", :id => user.id} }
                else
                    render json: @users.map { |user| {:label => user.name, :position_title => user.title.to_s, :district => user.district.present? ? user.district.name : "", :id => user.id} }
                end
            }
        end
    end

    def show
        @user = User.find_by_id(params[:id])
        not_found unless @user.present? && @user.company == current_user.company

        @activities = Activity.activities_for_user(@user).paginate(page: params[:page], limit: 20)

        if !current_user.role.limit_to_assigned_jobs?
            @average_job_performance = average_job_performance @user.jobs
            job_count = @user.jobs.count
        end
    end


    def edit
        store_last_location

        @user = User.find_by_id(params[:id])
        not_found unless @user.company == current_user.company
        @districts = current_user.company.districts

        @rigs = Rig.includes(:wells)

    end

    def update

        @user = User.find(params[:id])
        not_found unless @user.company == current_user.company

        User.transaction do


            if  @user.update_attribute(:name, params[:user][:name])
                @user.update_attribute(:email, params[:user][:email])
                @user.update_attribute(:location, params[:user][:location])
                @user.update_attribute(:phone_number, params[:user][:phone_number])
                @user.update_attribute(:district_id, params[:user][:district_id])
                @user.update_attribute(:role_id, params[:user][:role_id])

                Activity.add(self.current_user, Activity::USER_UPDATED, @user, @user.name)
                flash[:success] = "User updated"
                redirect_back_or users_path
            else
                @rigs = Rig.includes(:wells)
                render 'edit'
            end
        end
    end

    def new
        store_location

        @user = User.new

        @company = current_user.company
        if signed_in_admin?
            @company = Company.find(params[:id])
            session[:company_id] = params[:id]
        end

        @districts = @company.districts
        @rigs = Rig.includes(:wells)


        @autogenerated_password = SecureRandom.hex(8)[1..8]
    end

    def create
        district_id = params[:user][:district_id]
        params[:user].delete(:district_id)

        role_id = params[:user][:role_id]
        params[:user].delete(:role_id)

        rig_id = params[:user][:rig_id]
        params[:user].delete(:rig_id)

        use_generated_password =  params[:use_generated_password]
        @autogenerated_password =  params[:generated_password]
        custom_password =  params[:custom_password]

        @user = User.new(params[:user])
        @districts = current_user.company.districts
        @user.company = current_user.company
        @user.district = District.find_by_id(district_id)
        @user.role_id = role_id

        if @user.role_id == UserRole::ROLE_FIELD_ENGINEER
            @rig = Rig.find(rig_id)
            @user.restricted_rig = @rig
        end

        if use_generated_password
            @user.password = @autogenerated_password
            @user.password_confirmation = @autogenerated_password
        else
            @user.password = custom_password
            @user.password_confirmation = custom_password
        end
        #password = SecureRandom.urlsafe_base64[1..7]
        #@user.password = password
        #@user.password_confirmation = password

        @user.create_password = true

        if @user.district.present?
            @user.time_zone = @user.district.time_zone
        end

        if @user.save

            @user.delay.send_welcome_email(@user, @user.password)

            Activity.add(self.current_user, Activity::USER_CREATED, @user, @user.name)

            flash[:success] = "User created - #{@user.email}"

            if signed_in_admin?
                redirect_to "/admin/company/#{@user.company.id}/users"
            else
                redirect_to @user
            end
        else
            @districts = current_user.company.districts
            @rigs = Rig.includes(:wells)
            render 'new'
        end
    end

    def destroy
        @user = User.find_by_id(params[:id])
        not_found unless @user.company == current_user.company

        if !current_user?(@user)

            Activity.add(current_user, Activity::USER_DESTROYED, @user, @user.name)
            @user.destroy
            flash[:success] = "User destroyed."
            redirect_back_or users_path
        else
            flash[:error] = "Can't delete yourself."
            redirect_back_or users_path
        end
    end

    private

    def signed_in_support_role
        unless signed_in_admin? || current_user.role != UserRole::ROLE_FIELD_ENGINEER
            store_location
            flash[:error] = "Access is limited."
            redirect_to jobs_url
        end
    end


end
