component extends="quick.models.BaseEntity" {

    property name="id";
    property name="name";

    function posts() {
        return belongsToMany( "Post", "my_posts_tags", "tag_id", "post_pk" );
    }

}
