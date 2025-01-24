component extends="quick.models.BaseEntity" accessors="true" {

	property name="id";
	property name="name";
	property name="createdDate"  column="created_date";
	property name="modifiedDate" column="modified_date";

	function keyType() {
		return variables._wirebox.getInstance( "GUIDKeyType@quick" );
	}

}
