Chanelinkweb::Application.routes.draw do

  # home route
  root :to => "sessions#new"
  
  resources :properties do
    member do
      get 'show_embed'
      get 'edit_embed'
      post 'update_embed'
    end
    collection do
      get 'select'
      get 'do_select'
      get 'no_registered_property'
    end
  end

  resources :room_types do
    member do
      get 'delete'
    end
  end

  resources :pools do
    member do
      get 'delete'
      get 'edit_wizard_details'
      put 'edit_wizard_confirmation'
    end
    collection do
      get 'new_wizard_details'
      post 'new_wizard_confirmation'
      get 'done_creating'
    end
  end

  resources :property_channels do
    collection do
      post 'set_type'
      get 'new_wizard_selection'
      post 'new_wizard_setting'
      get 'new_wizard_setting'
      get 'new_wizard_conversion'
      post 'new_wizard_conversion'
      get 'new_wizard_rate_multiplier'
      post 'new_wizard_rate_multiplier'
      get 'new_wizard_confirm'
      post 'new_wizard_confirm'
      get 'done_creating'
    end
  end

  resources :members do
    member do
      get 'prompt_password'
      post 'prompt_password_set'
      get 'delete'
      get 'undelete'
    end
  end

  resources :room_type_channel_mappings do
    member do
      get 'delete'
    end
    collection do
      get 'new_wizard_channel_room'
      post 'new_wizard_channel_settings'
      get 'new_wizard_channel_settings'
      get 'new_wizard_rate'
      post 'new_wizard_rate'
      get 'new_wizard_confirm'
      post 'new_wizard_confirm'
      get 'done_creating'
    end
  end

  resources :room_type_inventory_links do
    member do
      get 'delete'
    end
  end

  match '/master_rate/pool_selection' => "room_type_master_rate_mappings#pool_selection", :as => "master_rate_pool_selection"

  resources :room_type_master_rate_mappings do
    member do
      get 'delete'
    end
  end
  
  resources :room_type_master_rate_channel_mappings do
    member do
      get 'delete'
    end
  end

  resource :session
  
  match '/inventories' => "inventories#grid", :as => "grid_inventories"
  match '/inventories/update' => "inventories#update", :as => "update_inventories"
  match '/inventories/pool_selection' => "inventories#pool_selection", :as => "inventories_pool_selection"

  match '/bulk_update' => "bulk_update#tool", :as => 'bulk_update'
  match '/bulk_update/submit' => "bulk_update#submit", :as => 'bulk_update_submit'

  match '/copy_tool' => "copy_tool#tool", :as => 'copy_tool'
  match '/copy_tool/submit' => "copy_tool#submit", :as => 'copy_tool_submit'

  match '/currency_conversion' => "currency_conversion#index", :as => 'currency_conversion'
  match '/currency_conversion/edit' => "currency_conversion#edit", :as => 'edit_currency_conversion'
  match '/currency_conversion/submit' => "currency_conversion#submit", :as => 'submit_currency_conversion'
  
  match '/channel_rates/update' => "channel_rates#update", :as => "update_channel_rates"
  match '/master_rates/update' => "master_rates#update", :as => "update_master_rates"

  match '/alerts' => "alerts#index", :as => "alerts"
  match '/alerts/delete' => "alerts#delete", :as => "alerts_delete"

  match '/reports/checkin' => "reports#checkin", :as => "checkin_reports"
  match '/reports/channel_yield' => "reports#channel_yield", :as => "channel_yield_reports"
  match '/reports/channel_trends' => "reports#channel_trends", :as => "channel_trends_reports"

  match '/get_bookings' => "bookings#get"
  match '/confirm_bookingcom' => 'bookings#confirm_bookingcom_reservations'
  match '/clean_cc_info' => "bookings#clean_cc_info", :as => "bookings_clean_cc_info"

  # specific url of OTA to receive bookings
  match '/get_ctrip' => "bookings#get_ctrip"

  match '/login' => "sessions#new", :as => "login"
  match '/logout' => "sessions#destroy", :as => "logout"
  match '/inactive' => "sessions#inactive", :as => "inactive"
  match '/dashboard' => "dashboard#index", :as => "dashboard"
  match '/password/reset' => "passwords#reset", :as => "password_reset"
  match '/password/reset_submit' => "passwords#reset_submit", :as => "password_reset_submit"

  match '/populate_rack_rate/send' => "populate_rack_rate#handle", :as => "handle_rack_rate"
  match '/populate_min_stay/send' => "populate_min_stay#handle", :as => "handle_min_stay"

  # admin
  namespace :admin, {:path => 'backoffic3'} do
    root :to => "sessions#new"
    resource :session

    match '/login' => "sessions#new", :as => "login"
    match '/logout' => "sessions#destroy", :as => "logout"
    match '/dashboard' => "dashboard#index", :as => "dashboard"
    match '/xml_log' => "dashboard#xml_log", :as => "xml_log"
    match '/xml_body' => "dashboard#xml_body", :as => "xml_body"
    match '/rerun_change_set' => "dashboard#rerun_change_set", :as => "rerun_change_set"
    match '/select_property' => "context#select_property", :as => "select_property"
    match '/select_account' => "context#select_account", :as => "select_account"
    match '/select_property_set' => "context#select_property_set", :as => "select_property_set"
    match '/select_account_set' => "context#select_account_set", :as => "select_account_set"
    match '/switch_hotel' => "context#switch_property", :as => "switch_property"

    match '/broadcast_alert/new' => "broadcast_alert#new", :as => "new_broadcast_alert"
    match '/broadcast_alert/create' => "broadcast_alert#create", :as => "create_broadcast_alert"

    match '/password/reset' => "passwords#reset", :as => "password_reset"
    match '/password/reset_submit' => "passwords#reset_submit", :as => "password_reset_submit"

    match '/alerts' => "alerts#index", :as => "alerts"

    resources :accounts do
      member do
        get 'delete'
        get 'activate'
      end
      collection do
        get 'new_wizard_for_account'
        post 'new_wizard_for_super_member'
        get 'done_creating'
      end
    end
    
    resources :property_channels do
      member do
        get 'approve'
        get 'edit_embed'
        get 'delete'
        put 'update_embed'
      end
      collection do
        get 'setup'
        get 'new_wizard_selection'
        post 'new_wizard_setting'
        get 'new_wizard_setting'
        get 'new_wizard_conversion'
        post 'new_wizard_conversion'
        get 'new_wizard_rate_multiplier'
        post 'new_wizard_rate_multiplier'
        get 'new_wizard_confirm'
        post 'new_wizard_confirm'
        get 'done_creating'
      end
    end

    resources :properties do
      member do
        put 'approve_reject'
        get 'delete'
        get 'manage'
      end
      collection do
        get 'done_creating'
      end
    end

    resources :users do
      member do
        get 'prompt_password'
        post 'prompt_password_set'
        get 'delete'
      end
    end

    resources :room_types do
      member do
        get 'delete'
      end
    end

    resources :room_type_channel_mappings do
      member do
        get 'delete'
      end
      collection do
        get 'new_wizard_channel_room'
        post 'new_wizard_channel_settings'
        get 'new_wizard_channel_settings'
        get 'new_wizard_rate'
        post 'new_wizard_rate'
        get 'new_wizard_confirm'
        post 'new_wizard_confirm'
        get 'done_creating'
      end
    end

    resources :members do
      member do
        get 'delete'
        get 'undelete'
      end
    end

    resources :configurations

    match '/bookings' => "bookings#index", :as => "bookings"
    match '/booking/:id' => "bookings#show", :as => "show_booking"
    match '/bookingcom_update' => "dashboard#bookingcom_update", :as => "bookingcom_update"
    match '/bookingcom_update_set' => "dashboard#bookingcom_update_set", :as => "bookingcom_update_set"
    match '/setup' => "setup#index", :as => "setup"
  end

   # match everything else and route to render error
  match '*a', :to => 'errors#render_error'
  
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
