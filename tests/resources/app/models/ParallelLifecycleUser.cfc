component
	table    ="users"
	extends  ="quick.models.BaseEntity"
	accessors="true"
{

	property name="id";

	function postLoad( eventData ) {
		param request.parallelLifecyclePostLoads = [];
		request.parallelLifecyclePostLoads.append( this );
	}

	function posts() {
		return hasMany( "Post", "user_id" );
	}

	function comments() {
		return hasMany( "Comment", "user_id" );
	}

	function postsLoaded( entity ) {
		arguments.entity.assignRelationship( "loadedByUser", this );
	}

}
