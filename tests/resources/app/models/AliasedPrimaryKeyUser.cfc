component
	extends  ="quick.models.BaseEntity"
	table    ="users"
	accessors="true"
{

	property name="userID" column="id";
	property name="username";
	property name="firstName" column="first_name";
	property name="lastName"  column="last_name";

	variables._key = "userID";

	function scopeWithFullName( qb ) {
		qb.appendVirtualAttribute( "fullName" ).selectRaw( "CONCAT(first_name, ' ', last_name) AS fullName" );
	}

}
