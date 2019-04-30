component extends="quick.models.Relationships.BaseRelationship" {

    function init( related, relationName, relationMethodName, parent, foreignKey, ownerKey ) {
        variables.ownerKey = arguments.ownerKey;
        variables.foreignKey = arguments.foreignKey;

        variables.child = arguments.parent;

        super.init( related, relationName, relationMethodName, parent );
    }

    function getResults() {
        if ( variables.child.isNullAttribute( variables.foreignKey ) ) {
            return javacast( "null", "" );
        }
        return variables.related.first();
    }

    function addConstraints() {
        var table = variables.related.get_Table();
        variables.related.where(
            "#table#.#variables.ownerKey#",
            "=",
            variables.child.retrieveAttribute( variables.foreignKey )
        );
    }

    function addEagerConstraints( entities ) {
        var key = variables.related.get_Table() & "." & variables.ownerKey;
        variables.related.whereIn( key, getEagerEntityKeys( entities ) );
    }

    function getEagerEntityKeys( entities ) {
        return entities.reduce( function( keys, entity ) {
            if ( ! isNull( entity.retrieveAttribute( variables.foreignKey ) ) ) {
                var key = entity.retrieveAttribute( variables.foreignKey );
                if ( key != "" ) {
                    keys[ key ] = {};
                }
            }
            return keys;
        }, {} ).keyArray();
    }

    function initRelation( entities, relation ) {
        entities.each( function( entity ) {
            entity.assignRelationship( relation, javacast( "null", "" ) );
        } );
        return entities;
    }

    function match( entities, results, relation ) {
        var dictionary = results.reduce( function( dict, result ) {
            dict[ result.retrieveAttribute( variables.ownerKey ) ] = result;
            return dict;
        }, {} );

        entities.each( function( entity ) {
            if ( structKeyExists( dictionary, entity.retrieveAttribute( variables.foreignKey ) ) ) {
                entity.assignRelationship( relation, dictionary[ entity.retrieveAttribute( variables.foreignKey ) ] );
            }
        } );

        return entities;
    }

    function associate( entity ) {
        var ownerKeyValue = isSimpleValue( entity ) ? entity : entity.retrieveAttribute( variables.ownerKey );
        variables.child.assignAttribute( variables.foreignKey, ownerKeyValue );
        if ( ! isSimpleValue( entity ) ) {
            variables.child.assignRelationship( variables.relationMethodName, entity );
        }
        return variables.child;
    }

    function dissociate() {
        variables.child.clearAttribute( variables.foreignKey, true );
        return variables.child.clearRelationship( variables.relationMethodName );
    }

}
