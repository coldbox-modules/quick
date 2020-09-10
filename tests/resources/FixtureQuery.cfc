component accessors="true" {

    property name="mapping" type="string";
    property name="mappingFileName" type="string";
    property name="definitions" type="struct";
    property name="_asEntities" type="boolean";
    property name="entityService";

    public FixtureQuery function init(
        required string mapping,
        required string mappingFileName,
        required struct definitions,
        required any entityService,
        boolean asEntities = false
    ) {
        variables.mapping = arguments.mapping;
        variables.mappingFileName = arguments.mappingFileName;
        variables.definitions = arguments.definitions;
        variables.entityService = arguments.entityService;
        variables._asEntities = arguments.asEntities;
        return this;
    }

    public FixtureQuery function asEntity() {
        variables._asEntities = true;
        return this;
    }

    public FixtureQuery function asEntities() {
        variables._asEntities = true;
        return this;
    }

    public any function all() {
        return transformEntities( variables.definitions );
    }

    public any function first() {
        for ( var definition in variables.definitions ) {
            return transformEntity( definition );
        }
    }

    public any function find( required string key ) {
        if ( !variables.definitions.keyExists( key ) ) {
            throw( "No definition exists for [#key#] in the [#mappingFileName#] fixture file." );
        }
        return transformEntity( variables.definitions[ key ] );
    }

    public any function get( any keys = [] ) {
        arguments.keys = isArray( arguments.keys ) ? arguments.keys : arguments.keys.listToArray();
        return transformEntities(
            variables.definitions.filter( function( key ) {
                return arrayContainsNoCase( keys, key );
            } )
        );
    }

    private any function transformEntities( required struct definitions ) {
        return arguments.definitions.keyArray().map( function( key ) {
            return transformEntity( definitions[ key ] );
        } );
    }

    private any function transformEntity( required struct definition ) {
        return variables._asEntities ?
            loadEntity( definition ) :
            augmentDefinitionStruct( definition );
    }

    private any function loadEntity( required struct definition ) {
        if ( isNull( variables.entityService ) ) {
            throw( "No Quick entity found for #variables.mapping#" );
        }
        var keyValues = variables.entityService.keyNames().map( function( keyName ) {
            return definition[ keyName ];
        } );
        return entityService.findOrFail( keyValues );
    }
    
    private struct function augmentDefinitionStruct( required struct definition ) {
        arguments.definition.getEntity = function() {
            return loadEntity( definition );
        };
        return arguments.definition;
    }

}