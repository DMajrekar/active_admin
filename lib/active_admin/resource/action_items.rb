require 'active_admin/helpers/optional_display'

module ActiveAdmin

  class Resource
    module ActionItems

      # Add the default action items to a resource when it's
      # initialized
      def initialize(*args)
        super
      end

      # @return [Array] The set of action items for this resource
      def action_items
        @action_items ||= []
      end

      # Add a new action item to a resource
      #
      # @param [Hash] options valid keys include:
      #                 :only:  A single or array of controller actions to display
      #                         this action item on.
      #                 :except: A single or array of controller actions not to
      #                          display this action item on.
      def add_action_item(options = {}, &block)
        self.action_items << ActiveAdmin::ActionItem.new(options, &block)
      end

      # Returns a set of action items to display for a specific controller action
      #
      # @param [String, Symbol] action the action to retrieve action items for
      #
      # @return [Array] Array of ActionItems for the controller actions
      def action_items_for(action)
        unless @default_actions_added
          add_default_action_items
          @default_actions_added = true
        end

        action_items.select{|item| item.display_on?(action) }
      end

      # Clears all the existing action items for this resource
      def clear_action_items!
        @action_items = []
      end
      
      # Allows disabling of the default actions (new / edit / destroy)
      # based on the conditions provided
      #     :if
      #     :unless
      def disable_action_item_for(type, options)
        @disabled_default_actions ||= {}
        @disabled_default_actions[type.to_s] = options
      end

      def default_action_disabled?(type, resource = nil)
        return false unless @disabled_default_actions
        return false unless @disabled_default_actions[type]
        return @disabled_default_actions[type][:if].call(resource) if @disabled_default_actions[type][:if]
        return !@disabled_default_actions[type][:unless].call(resource) if @disabled_default_actions[type][:unless]
        return false
      end
      
      private

      # Adds the default action items to each resource
      def add_default_action_items
        # New Link on all actions except :new and :show
        add_action_item :except => [:new, :show] do
          if controller.action_methods.include?('new') && !active_admin_config.default_action_disabled?('new')
            link_to(I18n.t('active_admin.new_model', :model => active_admin_config.resource_name), new_resource_path)
          end
        end 

        # Edit link on show
        add_action_item :only => :show do
          if controller.action_methods.include?('edit') && !active_admin_config.default_action_disabled?('edit', resource)
            link_to(I18n.t('active_admin.edit_model', :model => active_admin_config.resource_name), edit_resource_path(resource))
          end
        end

        # Destroy link on show
        add_action_item :only => :show do
          if controller.action_methods.include?("destroy") && !active_admin_config.default_action_disabled?('destroy', resource)
            link_to(I18n.t('active_admin.delete_model', :model => active_admin_config.resource_name),
              resource_path(resource),
              :method => :delete, :confirm => I18n.t('active_admin.delete_confirmation'))
          end
        end
      end

    end
  end

  # Model class to store the data for ActionItems
  class ActionItem
    include ActiveAdmin::OptionalDisplay

    attr_accessor :block

    def initialize(options = {}, &block)
      @options, @block = options, block
      normalize_display_options!
    end
  end

end
