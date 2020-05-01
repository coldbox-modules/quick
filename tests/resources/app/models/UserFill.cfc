component extends="quick.models.BaseEntity" accessors="true" {

	property name="id";
	property name="fileroot";
    property name="fullName" update="false";
    property name="email";
    property name="password";
    property name="firstName";
    property name="lastName";
    property name="aboutMe";
    property name="createdDate" readonly="true";
    property name="updatedDate";
	property name="lastLogin";
	property name="avatarID";
	property name="headerID";

}
