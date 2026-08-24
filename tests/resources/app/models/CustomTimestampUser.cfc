component extends="quick.models.BaseEntity" accessors="true" table="users" {

	property name="id";
	property name="createdDate"  column="created_date";
	property name="modifiedDate" column="modified_date";

	public array function timestampFields() {
		return [ "createdDate" ];
	}

}
