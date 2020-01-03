component accessors="true" {

    /*====================================
    =            Dependencies            =
    ====================================*/
    property name="_builder" inject="QuickQB@quick" persistent="false";
    property name="_wirebox" inject="wirebox" persistent="false";
    property name="_str" inject="Str@str" persistent="false";
    property name="_settings" inject="coldbox:modulesettings:quick" persistent="false";
    property name="_interceptorService" inject="coldbox:interceptorService" persistent="false";
    property name="_entityCreator" inject="EntityCreator@quick" persistent="false";

    /*===========================================
    =            Metadata Properties            =
    ===========================================*/
    property name="_entityName" persistent="false";
    property name="_mapping" persistent="false";
    property name="_fullName" persistent="false";
    property name="_table" persistent="false";
    property name="_queryOptions" persistent="false";
    property name="_readonly" default="false" persistent="false";
    property name="_key" default="id" persistent="false";
    property name="_attributes" persistent="false";
    property name="_meta" persistent="false";
    property name="_nullValues" persistent="false";
    property name="_casts" persistent="false";

    /*=====================================
    =            Instance Data            =
    =====================================*/
    property name="_data" persistent="false";
    property name="_originalAttributes" persistent="false";
    property name="_relationshipsData" persistent="false";
    property name="_relationshipsLoaded" persistent="false";
    property name="_eagerLoad" persistent="false";
    property name="_loaded" persistent="false";
    property name="_globalScopeExclusions" persistent="false";

    function init( struct meta = {} ) {
        assignDefaultProperties();
        variables._meta = arguments.meta;
        return this;
    }

    function assignDefaultProperties() {
        assignAttributesData( {} );
        assignOriginalAttributes( {} );
        variables._globalScopeExclusions = [];
        param variables._meta = {};
        param variables._data = {};
        param variables._relationshipsData = {};
        param variables._relationshipsLoaded = {};
        param variables._eagerLoad = [];
        param variables._nullValues = {};
        param variables._casts = {};
        param variables._loaded = false;
    }

    function onDIComplete() {
        metadataInspection();
        fireEvent( "instanceReady", { entity = this } );
    }

    function keyType() {
        return variables._wirebox.getInstance( "AutoIncrementingKeyType@quick" );
    }

    function retrieveKeyType() {
        if ( isNull( variables.__keyType__ ) ) {
            variables.__keyType__ = keyType();
        }
        return variables.__keyType__;
    }

    /*==================================
    =            Attributes            =
    ==================================*/

    function keyName() {
        return variables._key;
    }

    function keyValue() {
        guardAgainstNotLoaded( "This instance is not loaded so the `keyValue` cannot be retrieved." );
        return retrieveAttribute( variables._key );
    }

    function retrieveAttributesData( aliased = false, withoutKey = false, withNulls = false ) {
        variables._attributes.keyArray().each( function( key ) {
            if ( variables.keyExists( key ) && ! isReadOnlyAttribute( key ) ) {
                assignAttribute( key, variables[ key ] );
            }
        } );
        return variables._data.reduce( function( acc, key, value ) {
            if ( withoutKey && key == variables._key ) {
                return acc;
            }
            if ( isNull( value ) || ( isNullValue( key, value ) && withNulls ) ) {
                acc[ aliased ? retrieveAliasForColumn( key ) : key ] = javacast( "null" , "" );
            } else {
                acc[ aliased ? retrieveAliasForColumn( key ) : key ] = value;
            }
            return acc;
        }, {} );
    }

    function retrieveAttributeNames( columnNames = false ) {
        return variables._attributes.reduce( function( items, key, value ) {
            items.append( columnNames ? value : key );
            return items;
        }, [] );
    }

    function forceClearAttribute( name, setToNull = false ) {
        arguments.force = true;
        return clearAttribute( argumentCollection = arguments );
    }

    function clearAttribute( name, setToNull = false, force = false ) {
        if ( arguments.force ) {
            if ( ! variables._attributes.keyExists( retrieveAliasForColumn( arguments.name ) ) ) {
                variables._attributes[ arguments.name ] = arguments.name;
                variables._meta.properties[ arguments.name ] = paramProperty( { "name" = arguments.name } );
                variables._meta.originalMetadata.properties.append( variables._meta.properties[ arguments.name ] );
            }
        }
        if ( arguments.setToNull ) {
            variables._data[ arguments.name ] = javacast( "null", "" );
            variables[ retrieveAliasForColumn( arguments.name ) ] = javacast( "null", "" );
        } else {
            variables._data.delete( arguments.name );
            variables.delete( retrieveAliasForColumn( arguments.name ) );
        }
        return this;
    }

    function assignAttributesData( attrs ) {
        if ( isNull( arguments.attrs ) ) {
            variables._loaded = false;
            variables._data = {};
            return this;
        }

        arguments.attrs.each( function( key, value ) {
            variables._data[ retrieveColumnForAlias( key ) ] = isNull( value ) ?
                javacast( "null", "" ) :
                castValueForGetter( key, value );
            variables[ retrieveAliasForColumn( key ) ] = isNull( value ) ?
                javacast( "null", "" ) :
                castValueForGetter( key, value );
        } );

        return this;
    }

    function fill( attributes, ignoreNonExistentAttributes = false ) {
        for ( var key in arguments.attributes ) {
            var value = arguments.attributes[ key ];
            var rs = tryRelationshipSetter( "set#key#", { "1" = value } );
			if ( ! isNull( rs ) ) { continue; }
			if( ! arguments.ignoreNonExistentAttributes && ! hasAttribute( key ) ) {
                guardAgainstNonExistentAttribute( key );
			} else if( hasAttribute( key ) ) {
                variables._data[ retrieveColumnForAlias( key ) ] = value;
				invoke( this, "set#retrieveAliasForColumn( key )#", { 1 = value } );
			}
            guardAgainstReadOnlyAttribute( key );
        }
        return this;
    }

    function hasAttribute( name ) {
        return structKeyExists( variables._attributes, retrieveAliasForColumn( arguments.name ) ) || variables._key == name;
    }

    function isColumnAlias( name ) {
        return structKeyExists( variables._attributes, arguments.name );
    }

    function retrieveColumnForAlias( name ) {
        return variables._attributes.keyExists( arguments.name ) ? variables._attributes[ arguments.name ] : arguments.name;
    }

    function retrieveAliasForColumn( name ) {
        return variables._attributes.reduce( function( acc, alias, column ) {
            return name == column ? alias : acc;
        }, arguments.name );
    }

    function transformAttributeAliases( attributes ) {
        return arguments.attributes.reduce( function( acc, key, value ) {
            if ( isColumnAlias( key ) ) {
                key = retrieveColumnForAlias( key );
            }
            acc[ key ] = value;
            return acc;
        }, {} );
    }

    function assignOriginalAttributes( attributes ) {
        variables._originalAttributes = duplicate( arguments.attributes );
        return this;
    }

    function markLoaded() {
        variables._loaded = true;
        return this;
    }

    function isLoaded() {
        return variables._loaded;
    }

    function isDirty() {
        // TODO: could store hash of incoming attrs and compare hashes.
        // that could get rid of `duplicate` in `assignOriginalAttributes`
        return ! deepEqual( variables._originalAttributes, retrieveAttributesData() );
    }

    function retrieveAttribute( name, defaultValue = "", bypassGetters = true ) {
        if ( variables.keyExists( retrieveAliasForColumn( name ) ) && ! isReadOnlyAttribute( name ) ) {
            forceAssignAttribute( name, variables[ retrieveAliasForColumn( name ) ] );
        }

        if ( ! variables._data.keyExists( retrieveColumnForAlias( arguments.name ) ) ) {
            return castValueForGetter(
                arguments.name,
                arguments.defaultValue
            );
        }

        var data = ! arguments.bypassGetters && variables.keyExists( "get" & retrieveAliasForColumn( arguments.name ) ) ?
            invoke( this, "get" & retrieveAliasForColumn( arguments.name ) ) :
            variables._data[ retrieveColumnForAlias( arguments.name ) ];

        return castValueForGetter(
            arguments.name,
            data
        );
    }

    function forceAssignAttribute( name, value ) {
        arguments.force = true;
        return assignAttribute( argumentCollection = arguments );
    }

    function assignAttribute( name, value, force = false ) {
        if ( arguments.force ) {
            if ( ! variables._attributes.keyExists( retrieveAliasForColumn( arguments.name ) ) ) {
                variables._attributes[ arguments.name ] = arguments.name;
                variables._meta.properties[ arguments.name ] = paramProperty( { "name" = arguments.name } );
                variables._meta.originalMetadata.properties.append( variables._meta.properties[ arguments.name ] );
            }
        } else {
            guardAgainstNonExistentAttribute( arguments.name );
            guardAgainstReadOnlyAttribute( arguments.name );
        }
        if ( isStruct( arguments.value ) ) {
            if ( ! structKeyExists( arguments.value, "keyValue" ) ) {
                throw(
                    type = "QuickNotEntityException",
                    message = "The value assigned to [#arguments.name#] is not a Quick entity.  Perhaps you forgot to add `persistent=""false""` to a new property?",
                    detail = isSimpleValue( arguments.value ) ? arguments.value : getMetadata( arguments.value ).fullname
                );
            }
            arguments.value = castValueForSetter( arguments.name, arguments.value.keyValue() );
        }
        variables._data[ retrieveColumnForAlias( arguments.name ) ] = castValueForSetter( arguments.name, arguments.value );
        variables[ retrieveAliasForColumn( arguments.name ) ] = castValueForSetter( arguments.name, arguments.value );
        return this;
    }

    function qualifyColumn( column ) {
        if ( findNoCase( ".", arguments.column ) != 0 ) {
            return arguments.column;
        }
        return variables._table & "." & arguments.column;
    }

    /*=====================================
    =            Query Methods            =
    =====================================*/

    function getEntities() {
        applyGlobalScopes();
        return retrieveQuery()
            .get( options = variables._queryOptions )
            .map( function( attrs ) {
                return newEntity()
                    .assignAttributesData( attrs )
                    .assignOriginalAttributes( attrs )
                    .markLoaded();
            } );
    }

    function all() {
        resetQuery();
        applyGlobalScopes();
        return newCollection(
            eagerLoadRelations(
                retrieveQuery().from( variables._table )
                    .get( options = variables._queryOptions )
                    .map( function( attrs ) {
                        return newEntity()
                            .assignAttributesData( attrs )
                            .assignOriginalAttributes( attrs )
                            .markLoaded();
                    } )
            )
        );
    }

    function get() {
        applyGlobalScopes();
        return newCollection(
            eagerLoadRelations( getEntities() )
        );
    }

    function first() {
        applyGlobalScopes();
        var attrs = retrieveQuery().first( options = variables._queryOptions );
        return structIsEmpty( attrs ) ?
            javacast( "null", "" ) :
            newEntity()
                .assignAttributesData( attrs )
                .assignOriginalAttributes( attrs )
                .markLoaded();
    }

    function find( id ) {
        fireEvent( "preLoad", { id = arguments.id, metadata = variables._meta } );
        applyGlobalScopes();
        var data = retrieveQuery()
            .from( variables._table )
            .find( arguments.id, variables._key, variables._queryOptions );
        if ( structIsEmpty( data ) ) {
            return;
        }
        return tap( loadEntity( data ), function( entity ) {
            fireEvent( "postLoad", { entity = entity } );
        } );
    }

    private function loadEntity( data ) {
        return newEntity()
            .assignAttributesData( arguments.data )
            .assignOriginalAttributes( arguments.data )
            .markLoaded();
    }

    function findOrFail( id ) {
        var entity = variables.find( arguments.id );
        if ( isNull( entity ) ) {
            throw(
                type = "EntityNotFound",
                message = "No [#variables._entityName#] found with id [#arguments.id#]"
            );
        }
        return entity;
    }

    function firstOrFail() {
        applyGlobalScopes();
        var attrs = retrieveQuery().first( options = variables._queryOptions );
        if ( structIsEmpty( attrs ) ) {
            throw(
                type = "EntityNotFound",
                message = "No [#variables._entityName#] found with constraints [#serializeJSON( retrieveQuery().getBindings() )#]"
            );
        }
        return newEntity()
            .assignAttributesData( attrs )
            .assignOriginalAttributes( attrs )
            .markLoaded();
    }

    function existsOrFail() {
        applyGlobalScopes();
        if ( ! retrieveQuery().exists() ) {
            throw(
                type = "EntityNotFound",
                message = "No [#variables._entityName#] found with constraints [#serializeJSON( retrieveQuery().getBindings() )#]"
            );
        }
        return true;
    }

    function newEntity( name ) {
        if ( isNull( arguments.name ) ) {
            return variables._entityCreator.new( this );
        }
        return variables._wirebox.getInstance( arguments.name );
    }

    function reset() {
        resetQuery();
        assignAttributesData( {} );
        assignOriginalAttributes( {} );
        variables._data = {};
        variables._relationshipsData = {};
        variables._relationshipsLoaded = {};
        variables._eagerLoad = [];
        variables._loaded = false;

        return this;
    }

    function fresh() {
        return variables.resetQuery().find( keyValue() );
    }

    function refresh() {
        variables._relationshipsData = {};
        variables._relationshipsLoaded = {};
        assignAttributesData(
            newQuery()
                .from( variables._table )
                .find( keyValue(), variables._key, variables._queryOptions )
        );
        return this;
    }

    /*===========================================
    =            Persistence Methods            =
    ===========================================*/

    function save() {
        guardNoAttributes();
        guardReadOnly();
        fireEvent( "preSave", { entity = this } );
        if ( variables._loaded ) {
            fireEvent( "preUpdate", { entity = this } );
            newQuery()
                .where( variables._key, keyValue() )
                .update(
                    retrieveAttributesData( withoutKey = true )
                        .filter( canUpdateAttribute )
                        .map( function( key, value, attributes ) {
                            if ( isNull( value ) || isNullValue( key, value ) ) {
                                return { value = "", nulls = true, null = true };
                            }
                            if ( attributeHasSqlType( key ) ) {
                                return { value = value, cfsqltype = getSqlTypeForAttribute( key ) };
                            }
                            return value;
                        } ),
                    variables._queryOptions
                );
            assignOriginalAttributes( retrieveAttributesData() );
            markLoaded();
            fireEvent( "postUpdate", { entity = this } );
        }
        else {
            resetQuery();
            retrieveKeyType().preInsert( this );
            fireEvent( "preInsert", { entity = this, attributes = retrieveAttributesData() } );
            var attrs = retrieveAttributesData()
                .filter( canInsertAttribute )
                .map( function( key, value, attributes ) {
                    if ( isNull( value ) || isNullValue( key, value ) ) {
                        return { value = "", nulls = true, null = true };
                    }
                    if ( attributeHasSqlType( key ) ) {
                        return { value = value, cfsqltype = getSqlTypeForAttribute( key ) };
                    }
                    return value;
                } );
            guardEmptyAttributeData( attrs );
            var result = retrieveQuery().insert(
                attrs,
                variables._queryOptions
            );
            retrieveKeyType().postInsert( this, result );
            assignOriginalAttributes( retrieveAttributesData() );
            markLoaded();
            fireEvent( "postInsert", { entity = this } );
        }
        fireEvent( "postSave", { entity = this } );

        return this;
    }

    function delete() {
        guardReadOnly();
        fireEvent( "preDelete", { entity = this } );
        guardAgainstNotLoaded( "This instance is not loaded so it cannot be deleted.  Did you maybe mean to use `deleteAll`?" );
        newQuery().delete( keyValue(), variables._key, variables._queryOptions );
        variables._loaded = false;
        fireEvent( "postDelete", { entity = this } );
        return this;
    }

    function update( attributes = {}, ignoreNonExistentAttributes = false ) {
        guardAgainstNotLoaded( "This instance is not loaded so it cannot be updated.  Did you maybe mean to use `updateAll`, `insert`, or `save`?" );
        fill( arguments.attributes, arguments.ignoreNonExistentAttributes );
        return save();
    }

    function create( attributes = {}, ignoreNonExistentAttributes = false ) {
        return newEntity().fill( arguments.attributes, arguments.ignoreNonExistentAttributes ).save();
    }

    function updateAll( attributes = {}, force = false ) {
        if ( ! arguments.force ) {
            guardReadOnly();
            guardAgainstReadOnlyAttributes( arguments.attributes );
        }
        return retrieveQuery().update( arguments.attributes, variables._queryOptions );
    }

    function deleteAll( ids = [] ) {
        guardReadOnly();
        if ( ! arrayIsEmpty( arguments.ids ) ) {
            retrieveQuery().whereIn( variables._key, arguments.ids );
        }
        return retrieveQuery().delete( options = variables._queryOptions );
    }

    /*=====================================
    =            Relationships            =
    =====================================*/

    function hasRelationship( name ) {
        return variables._meta.functionNames.contains( lcase( arguments.name ) );
    }

    function loadRelationship( name ) {
        arguments.name = isArray( arguments.name ) ? arguments.name : [ arguments.name ];
        arguments.name.each( function( n ) {
            var relationship = invoke( this, n );
            relationship.setRelationMethodName( n );
            assignRelationship( n, relationship.get() );
        } );
        return this;
    }

    function isRelationshipLoaded( name ) {
        return structKeyExists( variables._relationshipsLoaded, arguments.name );
    }

    function retrieveRelationship( name ) {
        return variables._relationshipsData.keyExists( arguments.name ) ?
            variables._relationshipsData[ arguments.name ] :
            javacast( "null", "" );
    }

    function assignRelationship( name, value ) {
        if ( ! isNull( arguments.value ) ) {
            variables._relationshipsData[ arguments.name ] = arguments.value;
        }
        variables._relationshipsLoaded[ arguments.name ] = true;
        return this;
    }

    function clearRelationships() {
        variables._relationshipsData = {};
        return this;
    }

    function clearRelationship( name ) {
        variables._relationshipsData.delete( arguments.name );
        return this;
    }

    private function belongsTo( relationName, foreignKey, ownerKey, relationMethodName ) {
        var related = variables._wirebox.getInstance( arguments.relationName );

        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = related.get_EntityName() & related.get_Key();
        }
        if ( isNull( arguments.ownerKey ) ) {
            arguments.ownerKey = related.get_Key();
        }
        if ( isNull( arguments.relationMethodName ) ) {
            arguments.relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] );
        }
        return variables._wirebox.getInstance( name = "BelongsTo@quick", initArguments = {
            related = related,
            relationName = arguments.relationName,
            relationMethodName = arguments.relationMethodName,
            parent = this,
            foreignKey = arguments.foreignKey,
            ownerKey = arguments.ownerKey
        } );
    }

    private function hasOne( relationName, foreignKey, localKey, relationMethodName ) {
        var related = variables._wirebox.getInstance( arguments.relationName );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = variables._entityName & variables._key;
        }
        if ( isNull( arguments.localKey ) ) {
            arguments.localKey = variables._key;
        }
        if ( isNull( arguments.relationMethodName ) ) {
            arguments.relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] );
        }
        return variables._wirebox.getInstance( name = "HasOne@quick", initArguments = {
            related = related,
            relationName = arguments.relationName,
            relationMethodName = arguments.relationMethodName,
            parent = this,
            foreignKey = arguments.foreignKey,
            localKey = arguments.localKey
        } );
    }

    private function hasMany( relationName, foreignKey, localKey, relationMethodName ) {
        var related = variables._wirebox.getInstance( arguments.relationName );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = variables._entityName & variables._key;
        }
        if ( isNull( arguments.localKey ) ) {
            arguments.localKey = variables._key;
        }
        if ( isNull( arguments.relationMethodName ) ) {
            arguments.relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] );
        }
        return variables._wirebox.getInstance( name = "HasMany@quick", initArguments = {
            related = related,
            relationName = arguments.relationName,
            relationMethodName = arguments.relationMethodName,
            parent = this,
            foreignKey = arguments.foreignKey,
            localKey = arguments.localKey
        } );
    }

    private function belongsToMany(
        relationName,
        table,
        foreignPivotKey,
        relatedPivotKey,
        parentKey,
        relatedKey,
        relationMethodName
    ) {
        var related = variables._wirebox.getInstance( arguments.relationName );
        if ( isNull( arguments.table ) ) {
            if ( compareNoCase( related.get_Table(), variables._table ) < 0 ) {
                arguments.table = lcase( "#related.get_Table()#_#variables._table#" );
            }
            else {
                arguments.table = lcase( "#variables._table#_#related.get_Table()#" );
            }
        }
        if ( isNull( arguments.foreignPivotKey ) ) {
            arguments.foreignPivotKey = variables._entityName & variables._key;
        }
        if ( isNull( arguments.relatedPivotKey ) ) {
            arguments.relatedPivotKey = related.get_entityName() & related.get_key();
        }
        if ( isNull( arguments.relationMethodName ) ) {
            arguments.relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] );
        }
        if ( isNull( arguments.parentKey ) ) {
            arguments.parentKey = variables._key;
        }
        if ( isNull( arguments.relatedKey ) ) {
            arguments.relatedKey = related.get_key();
        }
        return variables._wirebox.getInstance( name = "BelongsToMany@quick", initArguments = {
            related = related,
            relationName = arguments.relationName,
            relationMethodName = arguments.relationMethodName,
            parent = this,
            table = arguments.table,
            foreignPivotKey = arguments.foreignPivotKey,
            relatedPivotKey = arguments.relatedPivotKey,
            parentKey = arguments.parentKey,
            relatedKey = arguments.relatedKey
        } );
    }

    private function hasManyThrough( relationName, intermediateName, firstKey, secondKey, localKey, secondLocalKey, relationMethodName ) {
        var related = variables._wirebox.getInstance( arguments.relationName );
        var intermediate = variables._wirebox.getInstance( arguments.intermediateName );
        if ( isNull( arguments.firstKey ) ) {
            arguments.firstKey = intermediate.get_EntityName() & intermediate.get_Key();
        }
        if ( isNull( arguments.firstKey ) ) {
            arguments.firstKey = variables._entityName & variables._key;
        }
        if ( isNull( arguments.secondKey ) ) {
            arguments.secondKey = intermediate.get_entityName() & intermediate.get_key();
        }
        if ( isNull( arguments.localKey ) ) {
            arguments.localKey = variables._key;
        }
        if ( isNull( arguments.secondLocalKey ) ) {
            arguments.secondLocalKey = intermediate.get_key();
        }
        if ( isNull( arguments.relationMethodName ) ) {
            arguments.relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] );
        }
        return variables._wirebox.getInstance( name = "HasManyThrough@quick", initArguments = {
            related = related,
            relationName = arguments.relationName,
            relationMethodName = arguments.relationMethodName,
            parent = this,
            intermediate = intermediate,
            firstKey = arguments.firstKey,
            secondKey = arguments.secondKey,
            localKey = arguments.localKey,
            secondLocalKey = arguments.secondLocalKey
        } );
    }

    private function polymorphicHasMany( required relationName, required name, type, id, localKey, relationMethodName ) {
        var related = variables._wirebox.getInstance( arguments.relationName );

        if ( isNull( arguments.type ) ) {
            arguments.type = arguments.name & "_type";
        }
        if ( isNull( arguments.id ) ) {
            arguments.id = arguments.name & "_id";
        }
        var table = related.get_table();
        if ( isNull( arguments.localKey ) ) {
            arguments.localKey = variables._key;
        }
        if ( isNull( arguments.relationMethodName ) ) {
            arguments.relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] );
        }

        return variables._wirebox.getInstance( name = "PolymorphicHasMany@quick", initArguments = {
            related = related,
            relationName = arguments.relationName,
            relationMethodName = arguments.relationMethodName,
            parent = this,
            type = arguments.type,
            id = arguments.id,
            localKey = arguments.localKey
        } );
    }

    private function polymorphicBelongsTo( name, type, id, ownerKey ) {
        if ( isNull( arguments.name ) ) {
            arguments.name = lcase( callStackGet()[ 2 ][ "Function" ] );
        }
        if ( isNull( arguments.type ) ) {
            arguments.type = arguments.name & "_type";
        }
        if ( isNull( arguments.id ) ) {
            arguments.id = arguments.name & "_id";
        }
        var relationName = retrieveAttribute( arguments.type, "" );
        if ( relationName == "" ) {
            return variables._wirebox.getInstance( name = "PolymorphicBelongsTo@quick", initArguments = {
                related = this.set_EagerLoad( [] ).resetQuery(),
                relationName = relationName,
                relationMethodName = arguments.name,
                parent = this,
                foreignKey = arguments.id,
                ownerKey = "",
                type = arguments.type
            } );
        }
        var related = variables._wirebox.getInstance( relationName );
        if ( isNull( arguments.ownerKey ) ) {
            arguments.ownerKey = related.get_key();
        }
        return variables._wirebox.getInstance( name = "PolymorphicBelongsTo@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = arguments.name,
            parent = this,
            foreignKey = arguments.id,
            ownerKey = arguments.ownerKey,
            type = arguments.type
        } );
    }

    function with( relationName ) {
        if ( isSimpleValue( arguments.relationName ) && arguments.relationName == "" ) {
            return this;
        }
        arguments.relationName = isArray( arguments.relationName ) ? arguments.relationName : [ arguments.relationName ];
        arrayAppend( variables._eagerLoad, arguments.relationName, true );
        return this;
    }

    function eagerLoadRelations( entities ) {
        if ( arrayIsEmpty( arguments.entities ) || arrayIsEmpty( variables._eagerLoad ) ) {
            return entities;
        }

        arrayEach( variables._eagerLoad, function( relationName ) {
            entities = eagerLoadRelation( relationName, entities );
        } );

        return arguments.entities;
    }

    private function eagerLoadRelation( relationName, entities ) {
        var callback = function() {};
        if ( ! isSimpleValue( arguments.relationName ) ) {
            if ( ! isStruct( arguments.relationName ) ) {
                throw(
                    type = "QuickInvalidEagerLoadParameter",
                    message = "Only strings or structs are supported eager load parameters.  You passed [#serializeJSON( arguments.relationName )#"
                );
            }
            for ( var key in arguments.relationName ) {
                callback = arguments.relationName[ key ];
                arguments.relationName = key;
                break;
            }
        }
        var currentRelationship = listFirst( arguments.relationName, "." );
        var relation = invoke( this, currentRelationship ).resetQuery();
        callback( relation );
        relation.addEagerConstraints( arguments.entities );
        relation.with( listRest( arguments.relationName, "." ) );
        return relation.match(
            relation.initRelation( arguments.entities, currentRelationship ),
            relation.getEager(),
            currentRelationship
        );
    }

    /*=======================================
    =            QB Utilities            =
    =======================================*/

    public function resetQuery() {
        newQuery();
        return this;
    }

    public function newQuery() {
        if ( variables._meta.originalMetadata.keyExists( "grammar" ) ) {
            variables._builder.setGrammar(
                variables._wirebox.getInstance( variables._meta.originalMetadata.grammar )
            );
        }
        variables.query = variables._builder.newQuery()
            .setReturnFormat( "array" )
            .setColumnFormatter( function( column ) {
                return retrieveColumnForAlias( column );
            } )
            .setParentQuery( this )
            .from( variables._table );
        return variables.query;
    }

    public function populateQuery( query ) {
        variables.query = arguments.query.clearParentQuery();
        return this;
    }

    public function retrieveQuery() {
        if ( ! structKeyExists( variables, "query" ) ) {
            variables.query = newQuery();
        }
        return variables.query;
    }

    public function addSubselect( name, subselect ) {
        if ( ! variables._attributes.keyExists( retrieveAliasForColumn( arguments.name ) ) ) {
            variables._attributes[ arguments.name ] = arguments.name;
            variables._meta.properties[ arguments.name ] = paramProperty( {
                "name" = arguments.name,
                "update" = false,
                "insert" = false
            } );
            variables._meta.originalMetadata.properties.append( variables._meta.properties[ arguments.name ] );
        }

        if (
            retrieveQuery().getColumns().isEmpty() ||
            (
                retrieveQuery().getColumns().len() == 1 &&
                isSimpleValue( retrieveQuery().getColumns()[ 1 ] ) &&
                retrieveQuery().getColumns()[ 1 ] == "*"
            )
        ) {
            retrieveQuery().select( retrieveQuery().getFrom() & ".*" );
        }

        var subselectQuery = arguments.subselect;
        if ( isClosure( subselectQuery ) ) {
            subselectQuery = retrieveQuery().newQuery();
            subselectQuery = arguments.subselect( subselectQuery );
        }

        retrieveQuery().subselect( name, subselectQuery.retrieveQuery().limit( 1 ) );
        return this;
    }

    /*=====================================
    =            Magic Methods            =
    =====================================*/

    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        var columnValue = tryColumnName( arguments.missingMethodName, arguments.missingMethodArguments );
        if ( ! isNull( columnValue ) ) { return columnValue; }
        var q = tryScopes( arguments.missingMethodName, arguments.missingMethodArguments );
        if ( ! isNull( q ) ) {
            if ( isStruct( q ) && structKeyExists( q, "retrieveQuery" ) ) {
                variables.query = q.retrieveQuery();
                return this;
            }
            return q;
        }
        var rg = tryRelationshipGetter( arguments.missingMethodName, arguments.missingMethodArguments );
        if ( ! isNull( rg ) ) { return rg; }
        var rs = tryRelationshipSetter( arguments.missingMethodName, arguments.missingMethodArguments );
        if ( ! isNull( rs ) ) { return rs; }
        if ( relationshipIsNull( arguments.missingMethodName ) ) {
            return javacast( "null", "" );
        }
        return forwardToQB( arguments.missingMethodName, arguments.missingMethodArguments );
    }

    private function tryColumnName( missingMethodName, missingMethodArguments ) {
        var getColumnValue = tryColumnGetters( arguments.missingMethodName );
        if ( ! isNull( getColumnValue ) ) { return getColumnValue; }
        var setColumnValue = tryColumnSetters( arguments.missingMethodName, arguments.missingMethodArguments );
        if ( ! isNull( setColumnValue ) ) { return this; }
        return;
    }

    private function tryColumnGetters( missingMethodName ) {
        if ( ! variables._str.startsWith( arguments.missingMethodName, "get" ) ) {
            return;
        }

        var columnName = variables._str.slice( arguments.missingMethodName, 4 );

        if ( hasAttribute( columnName ) ) {
            return retrieveAttribute( retrieveColumnForAlias( columnName ) );
        }

        return;
    }

    private function tryColumnSetters( missingMethodName, missingMethodArguments ) {
        if ( ! variables._str.startsWith( arguments.missingMethodName, "set" ) ) {
            return;
        }

        var columnName = variables._str.slice( arguments.missingMethodName, 4 );
        if ( ! hasAttribute( columnName ) ) {
            return;
        }
        assignAttribute( columnName, arguments.missingMethodArguments[ 1 ] );
        return arguments.missingMethodArguments[ 1 ];
    }

    private function tryRelationshipGetter( missingMethodName, missingMethodArguments ) {
        if ( ! variables._str.startsWith( arguments.missingMethodName, "get" ) ) {
            return;
        }

        var relationshipName = variables._str.slice( arguments.missingMethodName, 4 );

        if ( ! hasRelationship( relationshipName ) ) {
            return;
        }

        if ( ! isRelationshipLoaded( relationshipName ) ) {
            var relationship = invoke( this, relationshipName, arguments.missingMethodArguments );
            relationship.setRelationMethodName( relationshipName );
            assignRelationship( relationshipName, relationship.get() );
        }

        return retrieveRelationship( relationshipName );
    }

    private function tryRelationshipSetter( missingMethodName, missingMethodArguments ) {
        if ( ! variables._str.startsWith( arguments.missingMethodName, "set" ) ) {
            return;
        }

        var relationshipName = variables._str.slice( arguments.missingMethodName, 4 );

        if ( ! hasRelationship( relationshipName ) ) {
            return;
        }

        var relationship = invoke( this, relationshipName );

        return relationship.applySetter( argumentCollection = arguments.missingMethodArguments );
    }

    private function relationshipIsNull( name ) {
        if ( ! variables._str.startsWith( arguments.name, "get" ) ) {
            return false;
        }
        return variables._relationshipsLoaded.keyExists( variables._str.slice( arguments.name, 4 ) );
    }

    private function tryScopes( missingMethodName, missingMethodArguments ) {
        if ( structKeyExists( variables, "scope#arguments.missingMethodName#" ) ) {
            if ( arrayContains( variables._globalScopeExclusions, lcase( arguments.missingMethodName ) ) ) {
                return this;
            }
            var scopeArgs = { "1" = this };
            // this is to allow default arguments to be set for scopes
            if ( ! structIsEmpty( arguments.missingMethodArguments ) ) {
                for ( var i = 1; i <= structCount( arguments.missingMethodArguments ); i++ ) {
                    scopeArgs[ i + 1 ] = arguments.missingMethodArguments[ i ];
                }
            }
            var result = invoke( this, "scope#arguments.missingMethodName#", scopeArgs );
            return isNull( result ) ? this : result;
        }
        return;
    }

    function applyGlobalScopes() {
        return this;
    }

    function withoutGlobalScope( name ) {
        arguments.name = isArray( arguments.name ) ? arguments.name : [ arguments.name ];
        arguments.name.each( function( n ) {
            variables._globalScopeExclusions.append( lcase( n ) );
        } );
        return this;
    }

    private function forwardToQB( missingMethodName, missingMethodArguments ) {
        var result = invoke( retrieveQuery(), arguments.missingMethodName, arguments.missingMethodArguments );
        if ( isSimpleValue( result ) ) {
            return result;
        }
        return this;
    }

    function newCollection( array entities = [] ) {
        return arguments.entities;
    }

    function getMemento() {
        var data = variables._attributes.keyArray().reduce( function( acc, key ) {
            acc[ key ] = retrieveAttribute( name = key, bypassGetters = false );
            return acc;
        }, {} );
        var loadedRelations = variables._relationshipsData.reduce( function( acc, relationshipName, relation ) {
            if ( isArray( relation ) ) {
                var mementos = relation.map( function( r ) {
                    return r.getMemento();
                } );
                // ACF 11 doesn't let use directly assign the result of map
                // to a dynamic struct key. ¯\_(ツ)_/¯
                acc[ relationshipName ] = mementos;
            } else {
                acc[ relationshipName ] = relation.getMemento();
            }
            return acc;
        }, {} );
        structAppend( data, loadedRelations );
        return data;
    }

    function $renderdata() {
        return getMemento();
    }

    /*=======================================
    =            Other Utilities            =
    =======================================*/

    private function tap( value, callback ) {
        arguments.callback( arguments.value );
        return arguments.value;
    }

    private function metadataInspection() {
        if ( ! isStruct( variables._meta ) || structIsEmpty( variables._meta ) ) {
            var util = createObject( "component", "coldbox.system.core.util.Util" );
            variables._meta = {
                "originalMetadata" = util.getInheritedMetadata( this )
            };
        }
        param variables._key = "id";
        param variables._meta.fullName = variables._meta.originalMetadata.fullname;
        variables._fullName = variables._meta.fullName;
        param variables._meta.originalMetadata.mapping = listLast( variables._meta.originalMetadata.fullname, "." );
        param variables._meta.mapping = variables._meta.originalMetadata.mapping;
        variables._mapping = variables._meta.mapping;
        param variables._meta.originalMetadata.entityName = listLast( variables._meta.originalMetadata.name, "." );
        param variables._meta.entityName = variables._meta.originalMetadata.entityName;
        variables._entityName = variables._meta.entityName;
        param variables._meta.originalMetadata.table = variables._str.plural( variables._str.snake( variables._entityName ) );
        param variables._meta.table = variables._meta.originalMetadata.table;
        variables._table = variables._meta.table;
        param variables._queryOptions = {};
        if ( variables._queryOptions.isEmpty() && variables._meta.originalMetadata.keyExists( "datasource" ) ) {
            variables._queryOptions = { datasource = variables._meta.originalMetadata.datasource };
        }
        param variables._meta.originalMetadata.grammar = "AutoDiscover";
        param variables._meta.grammar = variables._meta.originalMetadata.grammar;
        variables._builder.setGrammar(
            variables._wirebox.getInstance( variables._meta.grammar & "@qb" )
        );
        param variables._meta.originalMetadata.readonly = false;
        param variables._meta.readonly = variables._meta.originalMetadata.readonly;
        variables._readonly = variables._meta.readonly;
        param variables._meta.originalMetadata.functions = [];
        param variables._meta.functionNames = generateFunctionNameList( variables._meta.originalMetadata.functions );
        param variables._meta.originalMetadata.properties = [];
        param variables._meta.properties = generateProperties( variables._meta.originalMetadata.properties );
        if ( ! variables._meta.properties.keyExists( variables._key ) ) {
            var keyProp = paramProperty( { "name" = variables._key } );
            variables._meta.properties[ keyProp.name ] = keyProp;
        }
        guardKeyHasNoDefaultValue();
        assignAttributesFromProperties( variables._meta.properties );
    }

    private function generateFunctionNameList( functions ) {
        return arguments.functions.map( function( func ) {
            return lcase( func.name );
        } );
    }

    private function generateProperties( properties ) {
        return arguments.properties.reduce( function( acc, prop ) {
            var newProp = paramProperty( prop );
            if ( ! newProp.persistent ) {
                return acc;
            }
            acc[ newProp.name ] = newProp;
            return acc;
        }, {} );
    }

    private function paramProperty( prop ) {
        param prop.column = arguments.prop.name;
        param prop.persistent = true;
        param prop.nullValue = "";
        param prop.convertToNull = true;
        param prop.casts = "";
        param prop.readOnly = false;
        param prop.sqltype = "";
        param prop.insert = true;
        param prop.update = true;
        return arguments.prop;
    }

    private function assignAttributesFromProperties( properties ) {
        for ( var alias in arguments.properties ) {
            var options = arguments.properties[ alias ];
            variables._attributes[ alias ] = options.column;
            if ( options.convertToNull ) {
                variables._nullValues[ alias ] = options.nullValue;
            }
            if ( options.casts != "" ) {
                variables._casts[ alias ] = options.casts;
            }
        }
        return this;
    }

    private function deepEqual( required expected, required actual ) {
        // Numerics
        if (
            isNumeric( arguments.actual ) &&
            isNumeric( arguments.expected ) &&
            compare( toString( arguments.actual ), toString( arguments.expected ) ) == 0
        ) {
            return true;
        }

        // Other Simple values
        if (
            isSimpleValue( arguments.actual ) &&
            isSimpleValue( arguments.expected ) &&
            compare( arguments.actual, arguments.expected ) == 0
        ) {
            return true;
        }

        // Queries
        if ( isQuery( arguments.actual ) && isQuery( arguments.expected ) ) {
            // Check number of records
            if ( arguments.actual.recordCount != arguments.expected.recordCount ) {
                return false;
            }

            // Get both column lists and sort them the same
            var actualColumnList = listSort( arguments.actual.columnList, "textNoCase" );
            var expectedColumnList = listSort( arguments.expected.columnList, "textNoCase" );

            // Check column lists
            if ( actualColumnList != expectedColumnList ) {
                return false;
            }

            for ( var i = 1; i <= arguments.actual.recordCount; i++ ) {
                for ( var column in listToArray( actualColumnList ) ) {
                    if ( arguments.actual[ column ][ i ] != arguments.expected[ column ][ i ] ) {
                        return false;
                    }
                }
            }

            return true;
        }

        // UDFs
        if (
            isCustomFunction( arguments.actual ) &&
            isCustomFunction( arguments.expected ) &&
            compare( arguments.actual.toString(), arguments.expected.toString() ) == 0
        ) {
            return true;
        }

        // XML
        if (
            IsXmlDoc( arguments.actual ) &&
            IsXmlDoc( arguments.expected ) &&
            compare( toString( arguments.actual ), toString( arguments.expected ) ) == 0
        ) {
            return true;
        }

        // Arrays
        if ( isArray( arguments.actual ) && isArray( arguments.expected ) ) {
            if ( arrayLen( arguments.actual ) neq arrayLen( arguments.expected ) ) {
                return false;
            }

            for ( var i = 1; i <= arrayLen( arguments.actual ); i++ ) {
                if ( arrayIsDefined( arguments.actual, i ) && arrayIsDefined( arguments.expected, i ) ) {
                    // check for both nulls
                    if ( isNull( arguments.actual[ i ] ) && isNull( arguments.expected[ i ] ) ) {
                        continue;
                    }
                    // check if one is null mismatch
                    if ( isNull( arguments.actual[ i ] ) || isNull( arguments.expected[ i ] ) ) {
                        return false;
                    }
                    // And make sure they match
                    if ( ! deepEqual( arguments.actual[ i ], arguments.expected[ i ] ) ) {
                        return false;
                    }
                    continue;
                }
                // check if both not defined, then continue to next element
                if ( ! arrayIsDefined( arguments.actual, i ) && ! arrayIsDefined( arguments.expected, i ) ) {
                    continue;
                } else {
                    return false;
                }
            }

            return true;
        }

        // Structs / Object
        if ( isStruct( arguments.actual ) && isStruct( arguments.expected ) ) {

            var actualKeys = listSort( structKeyList( arguments.actual ), "textNoCase" );
            var expectedKeys = listSort( structKeyList( arguments.expected ), "textNoCase" );

            if ( actualKeys != expectedKeys ) {
                return false;
            }

            // Loop over each key
            for ( var key in arguments.actual ) {
                // check for both nulls
                if ( isNull( arguments.actual[ key ] ) && isNull( arguments.expected[ key ] ) ) {
                    continue;
                }
                // check if one is null mismatch
                if ( isNull( arguments.actual[ key ] ) || isNull( arguments.expected[ key ] ) ) {
                    return false;
                }
                // And make sure they match when actual values exist
                if ( ! deepEqual( arguments.actual[ key ], arguments.expected[ key ] ) ) {
                    return false;
                }
            }

            return true;
        }

        return false;
    }

    /*=================================
    =            Read Only            =
    =================================*/

    private function guardReadOnly() {
        if ( isReadOnly() ) {
            throw(
                type = "QuickReadOnlyException",
                message = "[#variables._entityName#] is marked as a read-only entity."
            );
        }
    }

    private function isReadOnly() {
        return variables._readonly;
    }

    private function guardAgainstReadOnlyAttributes( attributes ) {
        for ( var name in arguments.attributes ) {
            guardAgainstReadOnlyAttribute( name );
        }
    }

    private function guardAgainstNonExistentAttribute( name ) {
        if ( ! hasAttribute( arguments.name ) ) {
            throw(
                type = "AttributeNotFound",
                message = "The [#arguments.name#] attribute was not found on the [#variables._entityName#] entity"
            );
        }
    }

    private function guardAgainstReadOnlyAttribute( name ) {
        if ( isReadOnlyAttribute( arguments.name ) ) {
            throw(
                type = "QuickReadOnlyException",
                message = "[#arguments.name#] is a read-only property on [#variables._entityName#]"
            );
        }
    }

    private function isReadOnlyAttribute( name ) {
        var alias = retrieveAliasForColumn( arguments.name );
        return variables._meta.properties.keyExists( alias ) &&
            variables._meta.properties[ alias ].readOnly;
    }

    private function guardNoAttributes() {
        if ( retrieveAttributeNames().isEmpty() ) {
            throw(
                type = "QuickNoAttributesException",
                message = "[#variables._entityName#] does not have any attributes specified."
            );
        }
    }

    private function guardEmptyAttributeData( required struct attrs ) {
        if ( arguments.attrs.isEmpty() ) {
            throw(
                type = "QuickNoAttributesDataException",
                message = "[#variables._entityName#] does not have any attributes data for insert."
            );
        }
    }

    private function guardAgainstNotLoaded( required string errorMessage ) {
        if ( ! isLoaded() ) {
            throw(
                type = "QuickEntityNotLoaded",
                message = arguments.errorMessage
            );
        }
    }

    private function guardKeyHasNoDefaultValue() {
        if ( variables._meta.properties.keyExists( variables._key ) ) {
            if ( variables._meta.properties[ variables._key ].keyExists( "default" ) ) {
                throw(
                    type = "QuickEntityDefaultedKey",
                    message = "The key value [#variables._key#] has a default value.  Default values on keys prevents Quick from working as expected.  Remove the default value to continue."
                );
            }
        }
    }

    /*==============================
    =            Events          =
    ==============================*/

    function fireEvent( eventName, eventData ) {
        arguments.eventData.entityName = variables._entityName;
        if ( eventMethodExists( arguments.eventName ) ) {
            invoke( this, arguments.eventName, { eventData = arguments.eventData } );
        }
        if ( ! isNull( variables._interceptorService ) ) {
            variables._interceptorService.processState( "quick" & arguments.eventName, arguments.eventData );
        }
    }

    private function eventMethodExists( eventName ) {
        return variables.keyExists( arguments.eventName );
    }

    private function attributeHasSqlType( name ) {
        var alias = retrieveAliasForColumn( arguments.name );
        return variables._meta.properties.keyExists( alias ) &&
            variables._meta.properties[ alias ].sqltype != "";
    }

    private function getSqlTypeForAttribute( name ) {
        var alias = retrieveAliasForColumn( arguments.name );
        return variables._meta.properties[ alias ].sqltype;
    }

    function isNullAttribute( key ) {
        return isNullValue( key, retrieveAttribute( key ) );
    }

    private function isNullValue( key, value ) {
        var alias = retrieveAliasForColumn( arguments.key );
        return variables._nullValues.keyExists( alias ) &&
            compare( variables._nullValues[ alias ], arguments.value ) == 0;
    }

    private function castValueForGetter( key, value ) {
        arguments.key = retrieveAliasForColumn( arguments.key );
        if ( ! structKeyExists( variables._casts, arguments.key ) ) {
            return arguments.value;
        }
        switch ( variables._casts[ arguments.key ] ) {
            case "boolean":
                return javacast( "boolean", arguments.value );
            default:
                return arguments.value;
        }
    }

    private function castValueForSetter( key, value ) {
        arguments.key = retrieveAliasForColumn( arguments.key );
        if ( ! structKeyExists( variables._casts, arguments.key ) ) {
            return arguments.value;
        }
        switch ( variables._casts[ arguments.key ] ) {
            case "boolean":
                return arguments.value ? 1 : 0;
            default:
                return arguments.value;
        }
    }

    private function canUpdateAttribute( name ) {
        var alias = retrieveAliasForColumn( arguments.name );
        return variables._meta.properties.keyExists( alias ) &&
            variables._meta.properties[ alias ].update;
    }

    private function canInsertAttribute( name ) {
        var alias = retrieveAliasForColumn( arguments.name );
        return variables._meta.properties.keyExists( alias ) &&
            variables._meta.properties[ alias ].insert;
    }

}
