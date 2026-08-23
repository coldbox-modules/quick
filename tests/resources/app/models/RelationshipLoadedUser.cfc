component
	table    ="users"
	extends  ="quick.models.BaseEntity"
	accessors="true"
{

	property name="id";

	function posts() {
		return hasMany( "Post", "user_id" );
	}

	function postsLoaded( entity ) {
		arguments.entity.assignRelationship( "loadedByUser", this );
	}

}
