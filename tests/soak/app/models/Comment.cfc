component extends="quick.models.BaseEntity" accessors="true" {

	property name="id";
	property name="body";
	property name="userId"          column="user_id";
	property name="commentableId"   column="commentable_id";
	property name="commentableType" column="commentable_type";
	function author() {
		return belongsTo( "User", "userId" );
	}
	function commentable() {
		return polymorphicBelongsTo( "commentable" );
	}

}
