component extends="quick.models.BaseEntity" accessors="true" {

	property name="id";
	property name="name";
	function posts() {
		return belongsToMany(
			"Post",
			"post_tags",
			"tag_id",
			"post_id"
		);
	}

}
