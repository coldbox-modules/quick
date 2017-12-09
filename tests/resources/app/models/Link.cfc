component extends="quick.models.BaseEntity" {

    property name="wirebox" inject="wirebox" persistent="false";

    property name="id" column="link_id";
    property name="url" column="link_url";

    variables.key = "link_id";

}
