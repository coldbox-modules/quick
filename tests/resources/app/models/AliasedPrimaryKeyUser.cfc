component
	extends  ="quick.models.BaseEntity"
	table    ="users"
	key      ="userID"
	accessors="true"
{

	property name="userID" column="id";
	property name="username";
	property name="firstName" column="first_name";
	property name="lastName"  column="last_name";

	function scopeWithFullName( qb ) {
		qb.appendVirtualAttribute( "fullName" ).selectRaw( "CONCAT(first_name, ' ', last_name) AS fullName" );
	}

}
