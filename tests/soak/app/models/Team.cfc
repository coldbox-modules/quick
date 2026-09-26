component extends="quick.models.BaseEntity" accessors="true" {

	property name="id";
	property name="name";
	function users() {
		return hasMany( "User", "teamId" );
	}

}
