component extends="quick.models.BaseEntity" accessors="true" {

    property name="id";
    property name="name";

    function posts() {
        return belongsToMany( "Post", "my_posts_tags", "tag_id", "custom_post_pk" );
    }

}
