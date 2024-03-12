component accessors="true" {

	property name="table" type="string";
	property name="alias" type="string";

	/**
	 * Used to quickly identify QueryBuilder instances
	 * instead of resorting to `isInstanceOf` which is slow.
	 */
	this.isBuilder = true;

	/**
	 * Used to quickly identify QuickBuilder instances
	 * instead of resorting to `isInstanceOf` which is slow.
	 */
	this.isQuickBuilder = true;

	/**
	 * Used to quickly identify PivotTable instances
	 * instead of resorting to `isInstanceOf` which is slow.
	 */
	this.isPivotTable = true;

	public string function tableName() {
		return variables.table;
	}

	public string function tableAlias() {
		return listLen( variables.table, " " ) > 1 ? listLast( variables.table, " " ) : variables.table;
	}

	public PivotTable function withAlias( required string alias ) {
		variables.alias = arguments.alias;
		return this;
	}

	public string function qualifyColumn( required string columnName ) {
		if ( findNoCase( ".", columnName ) > 0 ) {
			return columnName;
		}

		return isNull( variables.alias ) ? "#variables.table#.#arguments.columnName#" : "#variables.alias#.#arguments.columnName#";
	}

	public array function getWheres() {
		return [];
	}

	public struct function getRawBindings() {
		return { "where" : [] };
	}

	public PivotTable function getEntity() {
		return this;
	}

}
