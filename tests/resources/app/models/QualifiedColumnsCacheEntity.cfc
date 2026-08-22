component
	table    ="users"
	extends  ="quick.models.BaseEntity"
	accessors="true"
{

	property name="id";
	property name="username";
	property name="firstName" column="first_name";

	public string function qualifyColumn(
		required string column,
		string tableName        = this.tableName(),
		boolean useParentLookup = true
	) {
		param request.qualifiedColumnsCalls = 0;
		request.qualifiedColumnsCalls++;
		return super.qualifyColumn( argumentCollection = arguments );
	}

}
