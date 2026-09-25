component extends="quick.models.BaseEntity" accessors="true" {

	property name="id";
	property name="teamId"      column="team_id";
	property name="displayName" column="display_name";
	property name="email";
	property name="nickname";
	property name="secret";
	property name="profile" casts="ProfileCast";
	this.memento = {
		"neverInclude" : [ "secret" ],
		"defaults"     : { "nickname" : javacast( "null", "" ) }
	};
	function team() {
		return belongsTo( "Team", "teamId" );
	}
	function posts() {
		return hasMany( "Post", "userId" );
	}
	function comments() {
		return polymorphicHasMany( "Comment", "commentable" );
	}

}
