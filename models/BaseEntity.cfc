component accessors="true" {

    property name="builder" inject="provider:Builder@qb" getter="false" setter="false";
    property name="wirebox" inject="wirebox" getter="false" setter="false";
    property name="str" inject="Str@str" getter="false" setter="false";

    property name="entityName";
    property name="fullName";
    property name="table";
    property name="key" default="id";

    property name="attributes";
    property name="relationships";
    property name="eagerLoad";
    property name="loaded";

    function init() {
        setAttributes( {} );
        setRelationships( {} );
        setEagerLoad( [] );
        setLoaded( false );
        metadataInspection();
        return this;
    }

    /*==================================
    =            Attributes            =
    ==================================*/
    
    function getKeyValue() {
        return variables.attributes[ getKey() ];
    }

    function setAttributes( attributes ) {
        if ( isNull( arguments.attributes ) ) {
            setLoaded( false );
            variables.attributes = {};
            return this;
        }
        setLoaded( true );
        variables.attributes = arguments.attributes;
        return this;
    }

    function getAttribute( name ) {
        return variables.attributes[ name ];
    }

    function setAttribute( name, value ) {
        variables.attribute[ name ] = value;
        return this;
    }

    /*=====================================
    =            Query Methods            =
    =====================================*/
    
    function all() {
        return eagerLoadRelations(
            newQuery().from( getTable() ).get()
                .map( function( attributes ) {
                    return wirebox.getInstance( getFullName() )
                    .setAttributes( attributes );
                } )
        );
    }

    function get() {
        return eagerLoadRelations(
            getQuery().get().map( function( attributes ) {
                return wirebox.getInstance( getFullName() )
                    .setAttributes( attributes );
            } )
        );
    }

    function first() {
        return wirebox.getInstance( getFullName() )
            .setAttributes( getQuery().first() );
    }

    function find( id ) {
        var attributes = getQuery().from( getTable() ).find( id, getKey() );
        if ( structIsEmpty( attributes ) ) {
            return;
        }
        return wirebox.getInstance( getFullName() )
            .setAttributes( attributes );
    }
    
    /*=====================================
    =            Relationships            =
    =====================================*/

    function getRelationship( name ) {
        return variables.relationships[ name ];
    }

    function setRelationship( name, value ) {
        variables.relationships[ name ] = value;
        return this;
    }

    private function belongsTo( mapping, foreignKey ) {
        var related = wirebox.getInstance( mapping );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = lcase( "#related.getEntityName()#_#related.getKey()#" );
        }
        if ( isNull( arguments.owningKey ) ) {
            arguments.owningKey = related.getKey();
        }
        return wirebox.getInstance( name = "BelongsTo@quick", initArguments = {
            related = related,
            foreignKey = foreignKey,
            owningKey = owningKey,
            foreignKeyValue = variables.attributes[ arguments.foreignKey ]
        } );
    }

    private function hasOne( mapping, foreignKey ) {
        var related = wirebox.getInstance( mapping );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = lcase( "#getEntityName()#_#getKey()#" );
        }
        return wirebox.getInstance( name = "HasOne@quick", initArguments = {
            related = related,
            foreignKey = foreignKey,
            foreignKeyValue = variables.attributes[ getKey() ]
        } );
    }

    private function hasMany( mapping, foreignKey ) {
        var related = wirebox.getInstance( mapping );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = lcase( "#getEntityName()#_#getKey()#" );
        }
        if ( isNull( arguments.owningKey ) ) {
            arguments.owningKey = "#getEntityName()#_#getKey()#";
        }
        return wirebox.getInstance( name = "HasMany@quick", initArguments = {
            related = related,
            foreignKey = foreignKey,
            foreignKeyValue = variables.attributes[ getKey() ],
            owningKey = owningKey
        } );
    }

    function with( relationName ) {
        arrayAppend( variables.eagerLoad, relationName );
        return this;
    }

    private function eagerLoadRelations( entities ) {
        if ( arrayIsEmpty( entities ) || arrayIsEmpty( variables.eagerLoad ) ) {
            return entities;
        }

        arrayEach( variables.eagerLoad, function( relationName ) {
            entities = eagerLoadRelation( relationName, entities );
        } );

        return entities;
    }

    private function eagerLoadRelation( relationName, entities ) {
        var keys = {};
        for ( var entity in entities ) {
            var foreignKeyValue = invoke( entity, relationName ).getForeignKeyValue();
            keys[ foreignKeyValue ] = 1;
        }
        keys = structKeyArray( keys );
        var relatedEntity = invoke( entities[ 1 ], relationName ).getRelated();
        var owningKey = invoke( entities[ 1 ], relationName ).getOwningKey();
        var relations = relatedEntity.whereIn( owningKey, keys ).get();

        return matchRelations( entities, relations, relationName );
    }

    private function matchRelations( entities, relations, relationName ) {
        var groupedRelations = {};
        var relationship = invoke( entities[ 1 ], relationName );
        for ( var relation in relations ) {
            var key = relation.getAttribute( relationship.getOwningKey() );
            if ( ! structKeyExists( groupedRelations, key ) ) {
                groupedRelations[ key ] = [];
            }
            arrayAppend( groupedRelations[ key ], relation );
        }
        for ( var entity in entities ) {
            var relationship = invoke( entity, relationName );
            if ( structKeyExists( groupedRelations, relationship.getForeignKeyValue() ) ) {
                entity.setRelationship( relationName, groupedRelations[ relationship.getForeignKeyValue() ] );
            }
            else {
                entity.setRelationship( relationName, relationship.getDefaultValue() );
            }
        }
        return entities;
    }

    /*=======================================
    =            QB Utilities            =
    =======================================*/

    private function newQuery() {
        variables.query = builder.get().from( getTable() );
        return variables.query;
    }

    private function getQuery() {
        param variables.query = builder.get().from( getTable() );
        return variables.query;
    }

    /*=====================================
    =            Magic Methods            =
    =====================================*/

    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        var columnValue = tryColumnName( missingMethodName );
        if ( ! isNull( columnValue ) ) { return columnValue; }
        var q = tryScopes( missingMethodName, missingMethodArguments );
        if ( ! isNull( q ) ) {
            variables.query = q;
            return this;
        }
        var r = tryRelationships( missingMethodName );
        if ( ! isNull( r ) ) { return r; }
        return forwardToQB( missingMethodName, missingMethodArguments );
    }

    private function tryColumnName( missingMethodName ) {
        if ( len( missingMethodName ) < 3 || left( missingMethodName, 3 ) != "get" ) {
            return;
        }

        var columnName = mid( missingMethodName, 4, len( missingMethodName ) - 3 );

        if ( structKeyExists( variables.attributes, columnName ) ) {
            return getAttribute( columnName );
        }

        var snakeCaseColumnName = str.snake( columnName );
        if ( structKeyExists( variables.attributes, snakeCaseColumnName ) ) {
            return getAttribute( snakeCaseColumnName );
        }

        return;
    }

    private function tryRelationships( missingMethodName ) {
        if ( len( missingMethodName ) < 3 || left( missingMethodName, 3 ) != "get" ) {
            return;
        }

        var relationshipName = mid( missingMethodName, 4, len( missingMethodName ) - 3 );

        if ( ! structKeyExists( variables.relationships, relationshipName ) ) {
            setRelationship( relationshipName, invoke( this, relationshipName ).retrieve() );
        }

        return getRelationship( relationshipName );
    }

    private function tryScopes( missingMethodName, missingMethodArguments ) {
        if ( structKeyExists( variables, "scope#missingMethodName#" ) ) {
            return invoke( this, "scope#missingMethodName#", {
                builder = getQuery(),
                args = missingMethodArguments
            } );
        }
        return;
    }

    private function forwardToQB( missingMethodName, missingMethodArguments ) {
        invoke( getQuery(), missingMethodName, missingMethodArguments );
        return this;
    }

    /*=======================================
    =            Other Utilities            =
    =======================================*/
    
    private function metadataInspection() {
        var md = getMetadata( this );
        setFullName( md.fullname );
        param md.entityName = listLast( md.name, "." );
        setEntityName( md.entityName );
        param md.table = pluralize( lcase( getEntityName() ) );
        setTable( md.table );
    }

    private function pluralize( word ) {
        // obviously needs to be better
        // probably defer to the Str module
        return word & "s";
    }

}