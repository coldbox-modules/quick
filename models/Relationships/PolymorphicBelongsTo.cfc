component extends="quick.models.Relationships.BelongsTo" {

    function init( related, relationName, relationMethodName, parent, foreignKey, ownerKey, type ) {
        variables.morphType = arguments.type;

        return super.init( related, relationName, relationMethodName, parent, foreignKey, ownerKey );
    }

    function addEagerConstraints( entities ) {
        variables.entities = arguments.entities;
        buildDictionary( variables.entities );
    }

    function buildDictionary( entities ) {
        variables.dictionary = entities.reduce( function( dict, entity ) {
            var type = entity.retrieveAttribute( variables.morphType );
            if ( ! structKeyExists( dict, type ) )  {
                dict[ type ] = {};
            }
            var key = entity.retrieveAttribute( variables.foreignKey );
            if ( ! structKeyExists( dict[ type ], key ) )  {
                dict[ type ][ key ] = [];
            }
            arrayAppend( dict[ type ][ key ], entity );
            return dict;
        }, {} );
    }

    function getResults() {
        return variables.ownerKey != "" ? super.getResults() : {};
    }

    function getEager() {
        structKeyArray( variables.dictionary ).each( function( type ) {
            matchToMorphParents( type, getResultsByType( type ) );
        } );

        return variables.entities;
    }

    function getResultsByType( type ) {
        var instance = createModelByType( type );
        var localOwnerKey = variables.ownerKey != "" ? variables.ownerKey : instance.get_Key();
        instance.with( variables.related.get_eagerLoad() );

        return instance.whereIn(
            instance.get_table() & "." & localOwnerKey,
            gatherKeysByType( type )
        ).get();
    }

    function gatherKeysByType( type ) {
        return unique( structReduce( variables.dictionary[ type ], function( acc, key, values ) {
            arrayAppend( acc, arrayFirst( values ).retrieveAttribute( variables.foreignKey ) );
            return acc;
        }, [] ) );
    }

    function createModelByType( type ) {
        return variables.wirebox.getInstance( type );
    }

    function matchToMorphParents( type, results ) {
        results.each( function( result ) {
            var ownerKeyValue = variables.ownerKey != "" ? result.retrieveAttribute( variables.ownerKey ) : result.keyValue();
            if ( structKeyExists( variables.dictionary[ type ], ownerKeyValue ) ) {
                var entities = variables.dictionary[ type ][ ownerKeyValue ];
                entities.each( function( entity ) {
                    entity.assignRelationship( variables.relationMethodName, result );
                } );
            }
        } );
    }

}
