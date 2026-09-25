component
	extends              ="quick.models.BaseEntity"
	accessors            ="true"
	createdDateAttribute ="createdAt"
	modifiedDateAttribute="updatedAt"
{

	property name="id";
	property name="userId" column="user_id";
	property name="title";
	property name="summary";
	property name="ownerToken"     column="owner_token";
	property name="createdAt"      column="created_at";
	property name="updatedAt"      column="updated_at";
	property name="lifecycleCount" column="lifecycle_count";
	property name="profile" casts="ProfileCast";
	this.memento = {
		"defaults" : {
			"summary"    : javacast( "null", "" ),
			"ownerToken" : javacast( "null", "" )
		}
	};
	function author() {
		return belongsTo( "User", "userId" );
	}
	function comments() {
		return polymorphicHasMany( "Comment", "commentable" );
	}
	function tags() {
		return belongsToMany(
			"Tag",
			"post_tags",
			"post_id",
			"tag_id"
		).using( "PostTag" ).withPivot( "context" );
	}
	function preInsert( eventData ) {
		setLifecycleCount( 1 );
	}
	function preUpdate( eventData ) {
		setLifecycleCount( getLifecycleCount() + 1 );
	}

}
