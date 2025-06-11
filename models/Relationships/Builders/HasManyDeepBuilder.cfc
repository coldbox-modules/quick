component accessors="true" {

	property name="wirebox" inject="wirebox";

	property name="relationName" type="string";
	property name="through"      type="array";
	property name="foreignKeys"  type="array";
	property name="localKeys"    type="array";

	public HasManyDeepBuilder function init( required any parent, required string relationMethodName ) {
		variables.parent             = arguments.parent;
		variables.relationMethodName = arguments.relationMethodName;

		variables.through     = [];
		variables.foreignKeys = [];
		variables.localKeys   = [];

		return this;
	}

	public HasManyDeepBuilder function throughEntity(
		required string entityName,
		required any foreignKey,
		required any localKey,
		function callback
	) {
		if ( !isNull( arguments.callback ) ) {
			variables.through.append( function() {
				var entity = "";
				var parts  = entityName.split( "\s(?:[Aa][Ss]\s)?" );
				var entity = variables.wirebox.getInstance( trim( parts[ 1 ] ) );
				if ( arrayLen( parts ) > 1 ) {
					entity.withAlias( trim( parts[ 2 ] ) );
				}
				return callback( entity );
			} );
		} else {
			variables.through.append( arguments.entityName );
		}
		variables.foreignKeys.append( arguments.foreignKey );
		variables.localKeys.append( arguments.localKey );
		return this;
	}

	public HasManyDeepBuilder function throughPivotTable(
		required string tableName,
		required any foreignKey,
		required any localKey
	) {
		variables.through.append( arguments.tableName );
		variables.foreignKeys.append( arguments.foreignKey );
		variables.localKeys.append( arguments.localKey );
		return this;
	}

	public HasManyDeepBuilder function throughPolymorphicEntity(
		required string entityName,
		required string type,
		required any foreignKey,
		required any localKey,
		function callback
	) {
		arguments.foreignKey = {
			"type"        : "morph",
			"morphType"   : arguments.type,
			"foreignKeys" : arguments.foreignKey
		};
		structDelete( arguments, "type" );
		return throughEntity( argumentCollection = arguments );
	}

	public HasManyDeep function toRelated(
		required any relationName,
		required any foreignKey,
		required any localKey,
		any callback
	) {
		variables.foreignKeys.append( arguments.foreignKey );
		variables.localKeys.append( arguments.localKey );

		var related = arguments.relationName;
		if ( !isNull( arguments.callback ) ) {
			related = function() {
				var entity = "";
				var parts  = relationName.split( "\s(?:[Aa][Ss]\s)?" );
				var entity = variables.wirebox.getInstance( trim( parts[ 1 ] ) );
				if ( arrayLen( parts ) > 1 ) {
					entity.withAlias( trim( parts[ 2 ] ) );
				}
				return callback( entity );
			};
		}

		return variables.parent.hasManyDeep(
			relationName       = related,
			through            = variables.through,
			foreignKeys        = variables.foreignKeys,
			localKeys          = variables.localKeys,
			relationMethodName = variables.relationMethodName
		);
	}

	public HasManyDeep function toPolymorphicRelated(
		required string relationName,
		required string type,
		required any foreignKey,
		required any localKey
	) {
		arguments.foreignKey = {
			"type"        : "morph",
			"morphType"   : arguments.type,
			"foreignKeys" : arguments.foreignKey
		};
		structDelete( arguments, "type" );
		return toRelated( argumentCollection = arguments );
	}

}
