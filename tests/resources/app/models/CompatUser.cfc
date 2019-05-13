component extends="quick.models.CBORMCompatEntity" table="users" accessors="true" {

    property name="id";
    property name="username";
    property name="firstName" column="first_name";
    property name="lastName" column="last_name";
    property name="password";
    property name="countryId" column="country_id";
    property name="createdDate" column="created_date";
    property name="modifiedDate" column="modified_date";
    property name="email" column="email" update=false insert=true;
    property name="type";

    property name="posts"
        singularname="post"
        cfc="models.Post"
        fieldtype="one-to-many"
        fkcolumn="user_id"
        inverse="true"
        lazy="extra";

}
