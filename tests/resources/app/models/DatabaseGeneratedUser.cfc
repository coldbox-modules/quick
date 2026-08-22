component extends="quick.models.BaseEntity" accessors="true" table="users" {

	property name="id";
	property name="username";
	property name="firstName"   column="first_name";
	property name="lastName"    column="last_name";
	property name="createdDate" column="created_date" refreshOnSave="true";

}
