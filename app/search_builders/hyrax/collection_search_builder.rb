module Hyrax
  # Our parent class is the generated SearchBuilder descending from Blacklight::SearchBuilder
  # It includes Blacklight::Solr::SearchBuilderBehavior, Hydra::AccessControlsEnforcement, Hyrax::SearchFilters
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/search_builder.rb Blacklight::SearchBuilder parent
  # @see https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr/search_builder_behavior.rb Blacklight::Solr::SearchBuilderBehavior
  # @see https://github.com/samvera/hyrax/blob/master/app/search_builders/hyrax/README.md SearchBuilders README
  # @note the default_processor_chain defined by Blacklight::Solr::SearchBuilderBehavior provides many possible points of override
  #
  # Allows :deposit as a valid type
  class CollectionSearchBuilder < ::SearchBuilder
    include FilterByType

    attr_reader :access

    # @overload initialize(scope)
    #   @param [Object] scope scope the scope where the filter methods reside in.
    # @overload initialize(processor_chain, scope)
    #   @param [List<Symbol>,TrueClass] processor_chain options a list of filter methods to run or true, to use the default methods
    #   @param [Object] scope the scope where the filter methods reside in.
    # @overload initialize(processor_chain, scope)
    #   @param [List<Symbol>,TrueClass] processor_chain options a list of filter methods to run or true, to use the default methods
    #   @param [Object] scope the scope where the filter methods reside in.
    #   @param [Symbol] access one of :edit, :read, or :deposit
    def initialize(*options) # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
      # This approach to processing the parameters is required because this is how blacklight deals with these parameters
      # and this is called from blacklight via controller calling solr_query.
      case options.size
      when 1
        @scope = options.first
        @access = :read
      when 2
        @processor_chain, @scope = options
        @access = :read
      when 3
        @processor_chain, @scope, @access = options
        @access = access.to_sym unless access.is_a? Symbol
      else
        raise ArgumentError, "wrong number of arguments. (#{options.size} for 1..3)"
      end
      @processor_chain = nil if processor_chain.blank?

      if processor_chain.present?
        super(processor_chain, scope)
      else
        super(scope)
      end
    end

    # Overrides Hydra::AccessControlsEnforcement
    def discovery_permissions
      if @access == :edit
        @discovery_permissions ||= ["edit"]
      else
        super
      end
    end

    # @return [String] Solr field name indicating default sort order
    def sort_field
      Solrizer.solr_name('title', :sortable)
    end

    # This overrides the models in FilterByType
    def models
      collection_classes
    end

    # Sort results by title if no query was supplied.
    # This overrides the default 'relevance' sort.
    def add_sorting_to_solr(solr_parameters)
      return if solr_parameters[:q]
      solr_parameters[:sort] ||= "#{sort_field} asc"
    end

    # If :deposit access is requested, check to see which collections the user has
    # deposit or manage access to.
    # @return [Array<String>] a list of filters to apply to the solr query
    def gated_discovery_filters
      return super if @access != :deposit
      ["{!terms f=id}#{collection_ids_for_deposit.join(',')}"]
    end

    private

      def collection_ids_for_deposit
        Hyrax::Collections::PermissionsService.collection_ids_for_deposit(ability: current_ability)
      end
  end
end
