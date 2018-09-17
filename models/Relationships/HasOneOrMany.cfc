component extends="quick.models.Relationships.BaseRelationship" accessors="true" {

    function init( related, relationName, relationMethodName, parent, foreignKey, localKey ) {
        variables.localKey = arguments.localKey;
        variables.foreignKey = arguments.foreignKey;

        return super.init( related, relationName, relationMethodName, parent );
    }

    function addConstraints() {
        variables.related.retrieveQuery()
            .where( variables.foreignKey, "=", getParentKey() )
            .whereNotNull( variables.foreignKey );
    }

    function addEagerConstraints( entities ) {
        variables.related.retrieveQuery().whereIn(
            variables.foreignKey, getKeys( entities, variables.localKey )
        );
    }

    function matchOne( entities, results, relation ) {
        arguments.type = "one";
        return matchOneOrMany( argumentCollection = arguments );
    }

    function matchMany( entities, results, relation ) {
        arguments.type = "many";
        return matchOneOrMany( argumentCollection = arguments );
    }

    function matchOneOrMany( entities, results, relation, type ) {
        var dictionary = buildDictionary( results );
        entities.each( function( entity ) {
            var key = entity.retrieveAttribute( variables.localKey );
            if ( structKeyExists( dictionary, key ) ) {
                entity.assignRelationship(
                    relation,
                    getRelationValue( dictionary, key, type )
                )
            }
        } );
        return entities;
    }

    function buildDictionary( results ) {
        return results.reduce( function( dict, result ) {
            var key = invoke( result, "get#variables.foreignKey#" );
            if ( ! structKeyExists( dict, key ) ) {
                dict[ key ] = [];
            }
            arrayAppend( dict[ key ], result );
            return dict;
        }, {} );
    }

    function getRelationValue( dictionary, key, type ) {
        var value = dictionary[ key ];
        return type == "one" ? value[ 1 ] : value;
    }

    function getParentKey() {
        return variables.parent.retrieveAttribute( variables.localKey );
    }

    function save( entity ) {
        setForeignAttributesForCreate( entity );
        return entity.save();
    }

    function create( attributes = {} ) {
        var newInstance = variables.related.newEntity().fill( attributes );
        setForeignAttributesForCreate( newInstance );
        return newInstance.save();
    }

    function setForeignAttributesForCreate( entity ) {
        entity.assignAttribute(
            getForeignKeyName(),
            getParentKey()
        );
    }

    function getForeignKeyName() {
        return arrayLast( listToArray( getQualifiedForeignKeyName(), "." ) );
    }

    function getQualifiedForeignKeyName() {
        return variables.foreignKey;
    }

}
