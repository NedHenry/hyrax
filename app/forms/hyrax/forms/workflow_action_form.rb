module Hyrax
  module Forms
    # Responsible for processing that the :current_ability (and
    # associated current_user) has taken a Sipity::WorkflowAction on
    # an object that has a Sipity::Entity.
    #
    # The form enforces that the action taken is valid.
    #
    # @see Ability
    # @see Sipity::WorkflowAction
    # @see Sipity::Entity
    # @see Hyrax::Workflow::ActionTakenService
    # @see Hyrax::Workflow::NotificationService
    # @see Hyrax::Workflow::PermissionQuery
    class WorkflowActionForm
      include ActiveModel::Validations
      extend ActiveModel::Translation

      def initialize(current_ability:, work:, attributes: {})
        @current_ability = current_ability
        @work = work
        @name = attributes.fetch(:name, false)
        @comment = attributes.fetch(:comment, nil)
        convert_to_sipity_objects!
      end

      attr_reader :current_ability, :work, :name, :comment

      def save
        return false unless valid?
        Workflow::WorkflowActionService.run(subject: subject,
                                            action: sipity_workflow_action,
                                            comment: comment)
        true
      end

      validates :name, :comment, presence: true
      validate :authorized_for_processing

      def authorized_for_processing
        return false if name.blank? # name is the action which converts to sipity_workflow_action
        return true if Hyrax::Workflow::PermissionQuery.authorized_for_processing?(
          user: subject.user,
          entity: subject.entity,
          action: sipity_workflow_action
        )
        errors.add(:base, :unauthorized)
        false
      end

      private

        def convert_to_sipity_objects!
          @subject = WorkflowActionInfo.new(work, current_user)
          @sipity_workflow_action = PowerConverter.convert_to_sipity_action(name, scope: subject.entity.workflow) { nil }
        end

        attr_reader :subject, :sipity_workflow_action

        delegate :current_user, to: :current_ability
    end
  end
end
