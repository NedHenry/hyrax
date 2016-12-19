module Hyrax
  class ActorFactory
    def self.stack_actors(curation_concern)
      [CreateWithRemoteFilesActor,
       CreateWithFilesActor,
       Hyrax::Actors::AddAsMemberOfCollectionsActor,
       Hyrax::Actors::AddToWorkActor,
       Hyrax::Actors::AssignRepresentativeActor,
       Hyrax::Actors::AttachFilesActor,
       Hyrax::Actors::ApplyOrderActor,
       Hyrax::Actors::InterpretVisibilityActor,
       DefaultAdminSetActor,
       Hyrax::Actors::InitializeWorkflowActor,
       ApplyPermissionTemplateActor,
       model_actor(curation_concern)]
    end

    def self.build(curation_concern, current_user)
      Actors::ActorStack.new(curation_concern,
                             current_user,
                             stack_actors(curation_concern))
    end

    def self.model_actor(curation_concern)
      actor_identifier = curation_concern.class.to_s.split('::').last
      "Hyrax::Actors::#{actor_identifier}Actor".constantize
    end
  end
end
