component
	table    ="my_posts"
	extends  ="quick.models.BaseEntity"
	accessors="true"
{

	property name="post_pk";
	property name="user_id";
	property name="body";
	property name="createdDate"   column="created_date";
	property name="modifiedDate"  column="modified_date";
	property name="publishedDate" column="published_date";
	property name="lifecycleEventVar"      persistent="false" fillable="true";
	property name="internalLifecycleState" persistent="false";

	variables._key = "post_pk";

	function author() {
		return belongsTo( "User", "user_id" );
	}

	function authorWithEmptyDefault() {
		return belongsTo( "User", "user_id" ).withDefault();
	}

	function authorWithDefaultAttributes() {
		return belongsTo( "User", "user_id" ).withDefault( {
			"firstName" : "Guest",
			"lastName"  : "User"
		} );
	}

	function authorWithCalllbackConfiguredDefault() {
		return belongsTo( "User", "user_id" ).withDefault( function( user, post ) {
			user.setUsername( post.getBody() );
		} );
	}

	function tags() {
		return belongsToMany(
			"Tag",
			"my_posts_tags",
			"custom_post_pk",
			"tag_id"
		);
	}

	function tagsWithPivot() {
		return belongsToMany(
			"Tag",
			"my_posts_tags",
			"custom_post_pk",
			"tag_id"
		).withPivot( [ "context", "active" ] );
	}

	function tagsAsSubscriptions() {
		return belongsToMany(
			"Tag",
			"my_posts_tags",
			"custom_post_pk",
			"tag_id"
		)
			.withPivot( "context" )
			.as( "subscription" );
	}

	function tagsWithCustomPivot() {
		return belongsToMany(
			"Tag",
			"my_posts_tags",
			"custom_post_pk",
			"tag_id"
		)
			.using( "PostTag" )
			.withPivot( [ "context", "active" ] );
	}

	function activeTags() {
		return belongsToMany(
			"Tag",
			"my_posts_tags",
			"custom_post_pk",
			"tag_id"
		)
			.withPivot( [ "context", "active" ] )
			.wherePivot( "active", true )
			.orderByPivot( "context" );
	}

	function timestampedTags() {
		return belongsToMany(
			"Tag",
			"my_posts_tags",
			"custom_post_pk",
			"tag_id"
		).withTimestamps( "created_date", "modified_date" );
	}

	function comments() {
		return polymorphicHasMany( "Comment", "commentable" );
	}

	function country() {
		return belongsToThrough( [ "author", "country" ] );
	}

	function commentingUsers() {
		return hasManyThrough( [ "comments", "author" ] ).distinct();
	}

	function scopeLatest( qb ) {
		return qb.orderBy( "created_date", "desc" );
	}

	function scopePublished( qb ) {
		qb.whereNotNull( "publishedDate" );
	}

}
