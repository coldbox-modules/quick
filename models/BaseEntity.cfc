component accessors="true" {

    /*====================================
    =            Dependencies            =
    ====================================*/
    property name="_builder" inject="provider:QuickQB@quick" persistent="false";
    property name="_wirebox" inject="wirebox" persistent="false";
    property name="_str" inject="provider:Str@str" persistent="false";
    property name="_settings" inject="coldbox:modulesettings:quick" persistent="false";
    property name="_interceptorService" inject="provider:coldbox:interceptorService" persistent="false";
    property name="_entityCreator" inject="provider:EntityCreator@quick" persistent="false";

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

    this.constraints = {};

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

    function keyValue() {
        return variables._data[ variables._key ];
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
        if ( force ) {
            if ( ! variables._attributes.keyExists( retrieveAliasForColumn( name ) ) ) {
                variables._attributes[ name ] = name;
                variables._meta.properties[ name ] = paramProperty( { "name" = name } );
                variables._meta.originalMetadata.properties.append( variables._meta.properties[ name ] );
            }
        }
        if ( setToNull ) {
            variables._data[ name ] = javacast( "null", "" );
            variables[ retrieveAliasForColumn( name ) ] = javacast( "null", "" );
        }
        else {
            variables._data.delete( name );
            variables.delete( retrieveAliasForColumn( name ) );
        }
        return this;
    }

    function assignAttributesData( attrs ) {
        if ( isNull( attrs ) ) {
            variables._loaded = false;
            variables._data = {};
            return this;
        }

        attrs.each( function( key, value ) {
            variables._data[ retrieveColumnForAlias( key ) ] = isNull( value ) ? javacast( "null", "" ) : value;
            variables[ retrieveAliasForColumn( key ) ] = isNull( value ) ? javacast( "null", "" ) : value;
        } );

        return this;
    }

    function fill( attributes ) {
        for ( var key in arguments.attributes ) {
            var value = arguments.attributes[ key ];
            var rs = tryRelationshipSetter( "set#key#", { "1" = value } );
            if ( ! isNull( rs ) ) { continue; }
            guardAgainstNonExistentAttribute( key );
            guardAgainstReadOnlyAttribute( key );
            variables._data[ retrieveColumnForAlias( key ) ] = value;
            invoke( this, "set#retrieveAliasForColumn( key )#", { 1 = value } );
        }
        return this;
    }

    function hasAttribute( name ) {
        return structKeyExists( variables._attributes, retrieveAliasForColumn( name ) ) || variables._key == name;
    }

    function isColumnAlias( name ) {
        return structKeyExists( variables._attributes, name );
    }

    function retrieveColumnForAlias( name ) {
        return variables._attributes.keyExists( name ) ? variables._attributes[ name ] : name;
    }

    function retrieveAliasForColumn( name ) {
        return variables._attributes.reduce( function( acc, alias, column ) {
            return name == column ? alias : acc;
        }, name );
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

    function isLoaded() {
        return variables._loaded;
    }

    function isDirty() {
        // TODO: could store hash of incoming attrs and compare hashes.
        // that could get rid of `duplicate` in `assignOriginalAttributes`
        return ! deepEqual( variables._originalAttributes, retrieveAttributesData() );
    }

    function retrieveAttribute( name, defaultValue = "" ) {
        return castValueForGetter(
            name,
            variables._data.keyExists( retrieveColumnForAlias( name ) ) ?
                variables._data[ retrieveColumnForAlias( name ) ] :
                defaultValue
        );
    }

    function forceAssignAttribute( name, value ) {
        arguments.force = true;
        return assignAttribute( argumentCollection = arguments );
    }

    function assignAttribute( name, value, force = false ) {
        if ( force ) {
            if ( ! variables._attributes.keyExists( retrieveAliasForColumn( name ) ) ) {
                variables._attributes[ name ] = name;
                variables._meta.properties[ name ] = paramProperty( { "name" = name } );
                variables._meta.originalMetadata.properties.append( variables._meta.properties[ name ] );
            }
        } else {
            guardAgainstNonExistentAttribute( name );
            guardAgainstReadOnlyAttribute( name );
        }
        if ( ! isSimpleValue( arguments.value ) ) {
            if ( ! structKeyExists( arguments.value, "keyValue" ) ) {
                throw(
                    type = "QuickNotEntityException",
                    message = "The value assigned to [#name#] is not a Quick entity.  Perhaps you forgot to add `persistent=""false""` to a new property?",
                    detail = isSimpleValue( value ) ? value : getMetadata( value ).fullname
                );
            }
            arguments.value = castValueForSetter( name, arguments.value.keyValue() );
        }
        variables._data[ retrieveColumnForAlias( name ) ] = castValueForSetter( name, value );
        variables[ retrieveAliasForColumn( name ) ] = castValueForSetter( name, value );
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
                    .set_Loaded( true );
            } );
    }

    function all() {
        resetQuery();
        applyGlobalScopes();
        return eagerLoadRelations(
            retrieveQuery().from( variables._table )
                .get( options = variables._queryOptions )
                .map( function( attrs ) {
                    return newEntity()
                        .assignAttributesData( attrs )
                        .assignOriginalAttributes( attrs )
                        .set_Loaded( true );
                } )
        );
    }

    function get() {
        applyGlobalScopes();
        return eagerLoadRelations( getEntities() );
    }

    function first() {
        applyGlobalScopes();
        var attrs = retrieveQuery().first( options = variables._queryOptions );
        return structIsEmpty( attrs ) ?
            javacast( "null", "" ) :
            newEntity()
                .assignAttributesData( attrs )
                .assignOriginalAttributes( attrs )
                .set_Loaded( true );
    }

    function find( id ) {
        fireEvent( "preLoad", { id = id, metadata = variables._meta } );
        applyGlobalScopes();
        var data = retrieveQuery()
            .from( variables._table )
            .find( id, variables._key, variables._queryOptions );
        if ( structIsEmpty( data ) ) {
            return;
        }
        return tap( loadEntity( data ), function( entity ) {
            fireEvent( "postLoad", { entity = entity } );
        } );
    }

    private function loadEntity( data ) {
        return newEntity()
            .assignAttributesData( data )
            .assignOriginalAttributes( data )
            .set_Loaded( true );
    }

    function findOrFail( id ) {
        var entity = variables.find( id );
        if ( isNull( entity ) ) {
            throw(
                type = "EntityNotFound",
                message = "No [#variables._entityName#] found with id [#id#]"
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
            .set_Loaded( true );
    }

    function newEntity( name ) {
        if ( isNull( arguments.name ) ) {
            return variables._entityCreator.new( this );
        }
        return variables._wirebox.getInstance( arguments.name );
    }

    function reset() {
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
            variables._loaded = true;
            fireEvent( "postUpdate", { entity = this } );
        }
        else {
            resetQuery();
            retrieveKeyType().preInsert( this );
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
            fireEvent( "preInsert", { entity = this, attributes = attrs } );
            guardEmptyAttributeData( attrs );
            var result = retrieveQuery().insert(
                attrs,
                variables._queryOptions
            );
            retrieveKeyType().postInsert( this, result );
            assignOriginalAttributes( retrieveAttributesData() );
            variables._loaded = true;
            fireEvent( "postInsert", { entity = this } );
        }
        fireEvent( "postSave", { entity = this } );

        return this;
    }

    function delete() {
        guardReadOnly();
        fireEvent( "preDelete", { entity = this } );
        newQuery().delete( keyValue(), variables._key, variables._queryOptions );
        variables._loaded = false;
        fireEvent( "postDelete", { entity = this } );
        return this;
    }

    function update( attributes = {} ) {
        fill( attributes );
        return save();
    }

    function create( attributes = {} ) {
        return newEntity().fill( attributes ).save();
    }

    function updateAll( attributes = {} ) {
        guardReadOnly();
        guardAgainstReadOnlyAttributes( attributes );
        return retrieveQuery().update( attributes, variables._queryOptions );
    }

    function deleteAll( ids = [] ) {
        guardReadOnly();
        if ( ! arrayIsEmpty( ids ) ) {
            retrieveQuery().whereIn( variables._key, ids );
        }
        return retrieveQuery().delete( options = variables._queryOptions );
    }

    /*=====================================
    =            Relationships            =
    =====================================*/

    function hasRelationship( name ) {
        var md = variables._meta.originalMetadata;
        param md.functions = [];
        return ! arrayIsEmpty( arrayFilter( md.functions, function( func ) {
            return compareNoCase( func.name, name ) == 0;
        } ) );
    }

    function isRelationshipLoaded( name ) {
        return structKeyExists( variables._relationshipsLoaded, name );
    }

    function retrieveRelationship( name ) {
        return variables._relationshipsData.keyExists( name ) ?
            variables._relationshipsData[ name ] :
            javacast( "null", "" );
    }

    function assignRelationship( name, value ) {
        if ( ! isNull( value ) ) {
            variables._relationshipsData[ name ] = value;
        }
        variables._relationshipsLoaded[ name ] = true;
        return this;
    }

    function clearRelationships() {
        variables._relationshipsData = {};
        return this;
    }

    function clearRelationship( name ) {
        variables._relationshipsData.delete( name );
        return this;
    }

    private function belongsTo( relationName, foreignKey, ownerKey, relationMethodName ) {
        var related = variables._wirebox.getInstance( relationName );

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
            relationName = relationName,
            relationMethodName = relationMethodName,
            parent = this,
            foreignKey = foreignKey,
            ownerKey = ownerKey
        } );
    }

    private function hasOne( relationName, foreignKey, localKey ) {
        var related = variables._wirebox.getInstance( relationName );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = variables._entityName & variables._key;
        }
        if ( isNull( arguments.localKey ) ) {
            arguments.localKey = variables._key;
        }
        return variables._wirebox.getInstance( name = "HasOne@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] ),
            parent = this,
            foreignKey = foreignKey,
            localKey = localKey
        } );
    }

    private function hasMany( relationName, foreignKey, localKey ) {
        var related = variables._wirebox.getInstance( relationName );
        if ( isNull( arguments.foreignKey ) ) {
            arguments.foreignKey = variables._entityName & variables._key;
        }
        if ( isNull( arguments.localKey ) ) {
            arguments.localKey = variables._key;
        }
        return variables._wirebox.getInstance( name = "HasMany@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] ),
            parent = this,
            foreignKey = foreignKey,
            localKey = localKey
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
        var related = variables._wirebox.getInstance( relationName );
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
            relationName = relationName,
            relationMethodName = relationMethodName,
            parent = this,
            table = arguments.table,
            foreignPivotKey = foreignPivotKey,
            relatedPivotKey = relatedPivotKey,
            parentKey = parentKey,
            relatedKey = relatedKey
        } );
    }

    private function hasManyThrough( relationName, intermediateName, firstKey, secondKey, localKey, secondLocalKey ) {
        var related = variables._wirebox.getInstance( relationName );
        var intermediate = variables._wirebox.getInstance( intermediateName );
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

        return variables._wirebox.getInstance( name = "HasManyThrough@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] ),
            parent = this,
            intermediate = intermediate,
            firstKey = firstKey,
            secondKey = secondKey,
            localKey = localKey,
            secondLocalKey = secondLocalKey
        } );
    }

    private function polymorphicHasMany( required relationName, required name, type, id, localKey ) {
        var related = variables._wirebox.getInstance( relationName );

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

        return variables._wirebox.getInstance( name = "PolymorphicHasMany@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = lcase( callStackGet()[ 2 ][ "Function" ] ),
            parent = this,
            type = type,
            id = id,
            localKey = localKey
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
                relationMethodName = name,
                parent = this,
                foreignKey = arguments.id,
                ownerKey = "",
                type = type
            } );
        }
        var related = variables._wirebox.getInstance( relationName );
        if ( isNull( ownerKey ) ) {
            arguments.ownerKey = related.get_key();
        }
        return variables._wirebox.getInstance( name = "PolymorphicBelongsTo@quick", initArguments = {
            related = related,
            relationName = relationName,
            relationMethodName = name,
            parent = this,
            foreignKey = arguments.id,
            ownerKey = ownerKey,
            type = type
        } );
    }

    function with( relationName ) {
        if ( isSimpleValue( relationName ) && relationName == "" ) {
            return this;
        }
        relationName = isArray( relationName ) ? relationName : [ relationName ];
        arrayAppend( variables._eagerLoad, relationName, true );
        return this;
    }

    function eagerLoadRelations( entities ) {
        if ( arrayIsEmpty( entities ) || arrayIsEmpty( variables._eagerLoad ) ) {
            return entities;
        }

        arrayEach( variables._eagerLoad, function( relationName ) {
            entities = eagerLoadRelation( relationName, entities );
        } );

        return entities;
    }

    private function eagerLoadRelation( relationName, entities ) {
        var callback = function() {};
        if ( ! isSimpleValue( relationName ) ) {
            if ( ! isStruct( relationName ) ) {
                throw(
                    type = "QuickInvalidEagerLoadParameter",
                    message = "Only strings or structs are supported eager load parameters.  You passed [#serializeJSON( relationName )#"
                );
            }
            for ( var key in relationName ) {
                callback = relationName[ key ];
                arguments.relationName = key;
                break;
            }
        }
        var currentRelationship = listFirst( relationName, "." );
        var relation = invoke( this, currentRelationship ).resetQuery();
        callback( relation );
        relation.addEagerConstraints( entities );
        relation.with( listRest( relationName, "." ) );
        return relation.match(
            relation.initRelation( entities, currentRelationship ),
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
                variables._wirebox.getInstance( variables._meta.originalMetadata.grammar & "@qb" )
            );
        }
        variables.query = variables._builder.newQuery()
            .setReturnFormat( "array" )
            .setColumnFormatter( function( column ) {
                return retrieveColumnForAlias( column );
            } )
            .from( variables._table );
        return variables.query;
    }

    public function retrieveQuery() {
        if ( ! structKeyExists( variables, "query" ) ) {
            variables.query = newQuery();
        }
        return variables.query;
    }

    public function addSubselect( name, subselect ) {
        if ( ! variables._attributes.keyExists( retrieveAliasForColumn( name ) ) ) {
            variables._attributes[ name ] = name;
            variables._meta.properties[ name ] = paramProperty( {
                "name" = name,
                "update" = false,
                "insert" = false
            } );
            variables._meta.originalMetadata.properties.append( variables._meta.properties[ name ] );
        }

        if ( retrieveQuery().getColumns().isEmpty() ||
        ( retrieveQuery().getColumns().len() == 1 && isSimpleValue( retrieveQuery().getColumns()[ 1 ] ) && retrieveQuery().getColumns()[ 1 ] == "*" ) ) {
            retrieveQuery().select( retrieveQuery().getFrom() & ".*" );
        }

        var subselectQuery = subselect;
        if ( isClosure( subselectQuery ) ) {
            subselectQuery = retrieveQuery().newQuery();
            subselectQuery = subselect( subselectQuery );
        }

        retrieveQuery().subselect( name, subselectQuery.retrieveQuery().limit( 1 ) );
        return this;
    }

    /*=====================================
    =            Magic Methods            =
    =====================================*/

    function onMissingMethod( missingMethodName, missingMethodArguments ) {
        var columnValue = tryColumnName( missingMethodName, missingMethodArguments );
        if ( ! isNull( columnValue ) ) { return columnValue; }
        var q = tryScopes( missingMethodName, missingMethodArguments );
        if ( ! isNull( q ) ) {
            variables.query = q.retrieveQuery();
            return this;
        }
        var rg = tryRelationshipGetter( missingMethodName, missingMethodArguments );
        if ( ! isNull( rg ) ) { return rg; }
        var rs = tryRelationshipSetter( missingMethodName, missingMethodArguments );
        if ( ! isNull( rs ) ) { return rs; }
        if ( relationshipIsNull( missingMethodName ) ) {
            return javacast( "null", "" );
        }
        return forwardToQB( missingMethodName, missingMethodArguments );
    }

    private function tryColumnName( missingMethodName, missingMethodArguments ) {
        var getColumnValue = tryColumnGetters( missingMethodName );
        if ( ! isNull( getColumnValue ) ) { return getColumnValue; }
        var setColumnValue = tryColumnSetters( missingMethodName, missingMethodArguments );
        if ( ! isNull( setColumnValue ) ) { return this; }
        return;
    }

    private function tryColumnGetters( missingMethodName ) {
        if ( ! variables._str.startsWith( missingMethodName, "get" ) ) {
            return;
        }

        var columnName = variables._str.slice( missingMethodName, 4 );

        if ( hasAttribute( columnName ) ) {
            return retrieveAttribute( retrieveColumnForAlias( columnName ) );
        }

        return;
    }

    private function tryColumnSetters( missingMethodName, missingMethodArguments ) {
        if ( ! variables._str.startsWith( missingMethodName, "set" ) ) {
            return;
        }

        var columnName = variables._str.slice( missingMethodName, 4 );
        if ( ! hasAttribute( columnName ) ) {
            return;
        }
        assignAttribute( columnName, missingMethodArguments[ 1 ] );
        return missingMethodArguments[ 1 ];
    }

    private function tryRelationshipGetter( missingMethodName, missingMethodArguments ) {
        if ( ! variables._str.startsWith( missingMethodName, "get" ) ) {
            return;
        }

        var relationshipName = variables._str.slice( missingMethodName, 4 );

        if ( ! hasRelationship( relationshipName ) ) {
            return;
        }

        if ( ! isRelationshipLoaded( relationshipName ) ) {
            var relationship = invoke( this, relationshipName, missingMethodArguments );
            relationship.setRelationMethodName( relationshipName );
            assignRelationship( relationshipName, relationship.get() );
        }

        return retrieveRelationship( relationshipName );
    }

    private function tryRelationshipSetter( missingMethodName, missingMethodArguments ) {
        if ( ! variables._str.startsWith( missingMethodName, "set" ) ) {
            return;
        }

        var relationshipName = variables._str.slice( missingMethodName, 4 );

        if ( ! hasRelationship( relationshipName ) ) {
            return;
        }

        var relationship = invoke( this, relationshipName );

        return relationship.applySetter( argumentCollection = missingMethodArguments );
    }

    private function relationshipIsNull( name ) {
        if ( ! variables._str.startsWith( name, "get" ) ) {
            return false;
        }
        return variables._relationshipsLoaded.keyExists( variables._str.slice( name, 4 ) );
    }

    private function tryScopes( missingMethodName, missingMethodArguments ) {
        if ( structKeyExists( variables, "scope#missingMethodName#" ) ) {
            if ( arrayContains( variables._globalScopeExclusions, lcase( missingMethodName ) ) ) {
                return this;
            }
            var scopeArgs = { "1" = this };
            // this is to allow default arguments to be set for scopes
            if ( ! structIsEmpty( missingMethodArguments ) ) {
                for ( var i = 1; i <= structCount( missingMethodArguments ); i++ ) {
                    scopeArgs[ i + 1 ] = missingMethodArguments[ i ];
                }
            }
            invoke( this, "scope#missingMethodName#", scopeArgs );
            return this;
        }
        return;
    }

    function applyGlobalScopes() {
        return this;
    }

    function withoutGlobalScope( name ) {
        variables.name = isArray( name ) ? name : [ name ];
        variables.name.each( function( n ) {
            variables._globalScopeExclusions.append( lcase( name ) );
        } );
        return this;
    }

    private function forwardToQB( missingMethodName, missingMethodArguments ) {
        var result = invoke( retrieveQuery(), missingMethodName, missingMethodArguments );
        if ( isSimpleValue( result ) ) {
            return result;
        }
        return this;
    }

    function getMemento() {
        return variables._attributes.keyArray().reduce( function( acc, key ) {
            acc[ key ] = retrieveAttribute( key );
            return acc;
        }, {} );
    }

    function $renderdata() {
        return getMemento();
    }

    /*=======================================
    =            Other Utilities            =
    =======================================*/

    private function tap( value, callback ) {
        callback( value );
        return value;
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
        param variables._meta.originalMetadata.readonly = false;
        param variables._meta.readonly = variables._meta.originalMetadata.readonly;
        variables._readonly = variables._meta.readonly;
        param variables._meta.originalMetadata.properties = [];
        param variables._meta.properties = generateProperties( variables._meta.originalMetadata.properties );
        assignAttributesFromProperties( variables._meta.properties );
    }

    private function generateProperties( properties ) {
        return properties.reduce( function( acc, prop ) {
            var newProp = paramProperty( prop );
            if ( ! newProp.persistent ) {
                return acc;
            }
            acc[ newProp.name ] = newProp;
            return acc;
        }, {} );
    }

    private function paramProperty( prop ) {
        param prop.column = prop.name;
        param prop.persistent = true;
        param prop.nullValue = "";
        param prop.convertToNull = true;
        param prop.casts = "";
        param prop.readOnly = false;
        return prop;
    }

    private function assignAttributesFromProperties( properties ) {
        for ( var alias in properties ) {
            var options = properties[ alias ];
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
        if ( ! hasAttribute( name ) ) {
            throw(
                type = "AttributeNotFound",
                message = "The [#name#] attribute was not found on the [#variables._entityName#] entity"
            );
        }
    }

    private function guardAgainstReadOnlyAttribute( name ) {
        if ( isReadOnlyAttribute( name ) ) {
            throw(
                type = "QuickReadOnlyException",
                message = "[#name#] is a read-only property on [#variables._entityName#]"
            );
        }
    }

    private function isReadOnlyAttribute( name ) {
        var md = variables._meta.originalMetadata;
        if ( ! md.keyExists( "properties" ) || arrayIsEmpty( md.properties ) ) {
            return false;
        }
        // TODO: use stored metadata and store as struct of struct
        var foundProperties = arrayFilter( md.properties, function( prop ) {
            return prop.name == name;
        } );
        if ( arrayIsEmpty( foundProperties ) ) {
            return false;
        }
        return foundProperties[ 1 ].keyExists( "readonly" ) && foundProperties[ 1 ].readonly;
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
        if ( attrs.isEmpty() ) {
            throw(
                type = "QuickNoAttributesDataException",
                message = "[#variables._entityName#] does not have any attributes data for insert."
            );
        }
    }

    /*==============================
    =            Events          =
    ==============================*/

    function fireEvent( eventName, eventData ) {
        eventData.entityName = variables._entityName;
        if ( eventMethodExists( eventName ) ) {
            invoke( this, eventName, { eventData = eventData } );
        }
        if ( ! isNull( variables._interceptorService ) ) {
            variables._interceptorService.processState( "quick" & eventName, eventData );
        }
    }

    private function eventMethodExists( eventName ) {
        return variables.keyExists( eventName );
    }

    private function attributeHasSqlType( name ) {
        return ! variables._meta.originalMetadata.properties.filter( function( property ) {
            return property.name == retrieveAliasForColumn( name ) && property.keyExists( "sqltype" );
        } ).isEmpty();
    }

    private function getSqlTypeForAttribute( name ) {
        return variables._meta.originalMetadata.properties.filter( function( property ) {
            return property.name == retrieveAliasForColumn( name );
        } )[ 1 ].sqltype;
    }

    function isNullAttribute( key ) {
        return isNullValue( key, retrieveAttribute( key ) );
    }

    private function isNullValue( key, value ) {
        return variables._nullValues.keyExists( retrieveAliasForColumn( key ) ) &&
            compare( variables._nullValues[ retrieveAliasForColumn( key ) ], value ) == 0;
    }

    private function castValueForGetter( key, value ) {
        arguments.key = retrieveAliasForColumn( arguments.key );
        if ( ! structKeyExists( variables._casts, key ) ) {
            return value;
        }
        switch ( variables._casts[ key ] ) {
            case "boolean":
                return javacast( "boolean", value );
            default:
                return value;
        }
    }

    private function castValueForSetter( key, value ) {
        arguments.key = retrieveAliasForColumn( arguments.key );
        if ( ! structKeyExists( variables._casts, key ) ) {
            return value;
        }
        switch ( variables._casts[ key ] ) {
            case "boolean":
                return value ? 1 : 0;
            default:
                return value;
        }
    }

    private function canUpdateAttribute( name ) {
        return ! variables._meta.originalMetadata.properties.filter( function( property ) {
            return property.name == retrieveAliasForColumn( name ) &&
                (
                    ! property.keyExists( "update" ) ||
                    (
                        property.keyExists( "update" ) &&
                        property.update
                    )
                );
        } ).isEmpty();
    }

    private function canInsertAttribute( name ) {
        return ! variables._meta.originalMetadata.properties.filter( function( property ) {
            return property.name == retrieveAliasForColumn( name ) &&
                (
                    ! property.keyExists( "insert" ) ||
                    (
                        property.keyExists( "insert" ) &&
                        property.insert
                    )
                );
        } ).isEmpty();
    }

    function timeIt( callback, label ) {
        var start = getTickCount();
        var result = callback();
        writeDump( var = getTickCount() - start, label = label );
        return isNull( result ) ? javacast( "null", "" ) : result;
    }

}
