/**
 * Represents one intermediate-table row for a belongs-to-many relationship.
 *
 * The default Pivot model is read-only because its schema is assembled from the
 * relationship at runtime. Extend this component and declare the pivot columns
 * as properties to opt in to explicit Quick persistence and custom behavior.
 */
component
	extends  ="quick.models.BaseEntity"
	accessors="true"
	readonly ="true"
{

	property name="_pivotParent"  persistent="false";
	property name="_pivotRelated" persistent="false";

	this.isPivot = true;

	/**
	 * Configures and hydrates this pivot for a relationship result.
	 */
	public Pivot function configurePivot(
		required string table,
		required array keyNames,
		required struct attributes,
		required any parent,
		required any related
	) {
		set_table( arguments.table );
		set_key( arguments.keyNames );
		variables._pivotParent  = arguments.parent;
		variables._pivotRelated = arguments.related;

		for ( var attributeName in arguments.attributes ) {
			if (
				!retrieveAttributeNames( withVirtualAttributes = true, withExcludedAttributes = true ).findNoCase(
					attributeName
				) &&
				!retrieveColumnNames( withVirtualAttributes = true ).findNoCase( attributeName )
			) {
				appendVirtualAttribute( attributeName );
			}
		}

		this.memento.defaultIncludes = retrieveAttributeNames( withVirtualAttributes = true );

		return assignAttributesData( arguments.attributes )
			.assignOriginalAttributes( arguments.attributes )
			.markLoaded();
	}

	/**
	 * Returns the parent entity which loaded this pivot.
	 */
	public any function getPivotParent() {
		return variables._pivotParent;
	}

	/**
	 * Returns the related entity carrying this pivot.
	 */
	public any function getPivotRelated() {
		return variables._pivotRelated;
	}

}
