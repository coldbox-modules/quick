component extends="quick.models.BaseEntity" {

    property name="wirebox" inject="wirebox" persistent="false";

    property name="link_id" column="link_id";
    property name="url" column="link_url";
    property name="createdDate" column="created_date" readonly="true";

    variables._key = "link_id";

}
