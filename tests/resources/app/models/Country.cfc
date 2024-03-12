component extends="quick.models.BaseEntity" accessors="true" {

	property name="id";
	property name="name";
	property name="createdDate"  column="created_date";
	property name="modifiedDate" column="modified_date";

	function users() {
		return hasMany( "User" );
	}

	function posts() {
		return hasManyThrough( [ "users", "posts" ] );
	}

	function postsDeep() {
		return hasManyDeep(
			relationName = "Post",
			through      = [ "User" ],
			foreignKeys  = [ "countryId", "user_id" ],
			localKeys    = [ "id", "id" ]
		);
	}

	function publishedPostsDeep() {
		return hasManyDeep(
			relationName = () => {
				return newEntity( "Post" ).published();
			},
			through     = [ "User" ],
			foreignKeys = [ "countryId", "user_id" ],
			localKeys   = [ "id", "id" ]
		);
	}

	function publishedPostsDeepBuilder() {
		return newHasManyDeepBuilder()
			.throughEntity(
				entityName = "User",
				foreignKey = "country_id",
				localKey   = "id"
			)
			.toRelated(
				relationName = "Post",
				foreignKey   = "user_id",
				localKey     = "id",
				callback     = ( post ) => post.published()
			);
	}

	function adminPostsDeep() {
		return hasManyDeep(
			relationName = "Post",
			through      = [ () => newEntity( "User" ).ofType( "limited" ) ],
			foreignKeys  = [ "countryId", "user_id" ],
			localKeys    = [ "id", "id" ]
		);
	}

	function adminPostsDeepAliased() {
		return hasManyDeep(
			relationName = "Post",
			through      = [ "User as u" ],
			foreignKeys  = [ "countryId", "user_id" ],
			localKeys    = [ "id", "id" ]
		).where( "u.firstName", "<>", "Eric" );
	}

	function adminPostsDeepBuilder() {
		return newHasManyDeepBuilder()
			.throughEntity(
				entityName = "User",
				foreignKey = "country_id",
				localKey   = "id",
				callback   = ( user ) => user.ofType( "limited" )
			)
			.toRelated(
				relationName = "Post",
				foreignKey   = "user_id",
				localKey     = "id"
			);
	}

	function postsDeepBuilder() {
		return newHasManyDeepBuilder()
			.throughEntity(
				entityName = "User",
				foreignKey = "country_id",
				localKey   = "id"
			)
			.toRelated(
				relationName = "Post",
				foreignKey   = "user_id",
				localKey     = "id"
			);
	}

	function postCommentsDeep() {
		return hasManyDeep(
			relationName = "Comment",
			through      = [ "User", "Post" ],
			foreignKeys  = [
				"country_id",
				"user_id",
				[ "commentable_type", "commentable_id" ]
			],
			localKeys = [ "id", "id", "post_pk" ]
		);
	}

	function postCommentsDeepBuilder() {
		return newHasManyDeepBuilder()
			.throughEntity( "User", "country_id", "id" )
			.throughEntity( "Post", "user_id", "id" )
			.toPolymorphicRelated(
				relationName = "Comment",
				type         = "commentable_type",
				foreignKey   = "commentable_id",
				localKey     = "post_pk"
			);
	}

	function postPublicCommentsDeep() {
		return hasManyDeep(
			relationName = "Comment",
			through      = [ "User", "Post" ],
			foreignKeys  = [
				"country_id",
				"user_id",
				[ "commentable_type", "commentable_id" ]
			],
			localKeys = [ "id", "id", "post_pk" ]
		).where( "comments.designation", "public" );
	}

	function postPublicCommentsDeepBuilder() {
		return newHasManyDeepBuilder()
			.throughEntity( "User", "country_id", "id" )
			.throughEntity( "Post", "user_id", "id" )
			.toPolymorphicRelated(
				relationName = "Comment",
				type         = "commentable_type",
				foreignKey   = "commentable_id",
				localKey     = "post_pk"
			)
			.where( "comments.designation", "public" );
	}

	function postPublicCommentsDeepAliased() {
		return hasManyDeep(
			relationName = "Comment AS c",
			through      = [ "User", "Post" ],
			foreignKeys  = [
				"country_id",
				"user_id",
				[ "commentable_type", "commentable_id" ]
			],
			localKeys = [ "id", "id", "post_pk" ]
		).where( "c.designation", "public" );
	}

	function postPublicCommentsDeepAliasedBuilder() {
		return newHasManyDeepBuilder()
			.throughEntity( "User", "country_id", "id" )
			.throughEntity( "Post", "user_id", "id" )
			.toPolymorphicRelated(
				relationName = "Comment AS c",
				type         = "commentable_type",
				foreignKey   = "commentable_id",
				localKey     = "post_pk"
			)
			.where( "c.designation", "public" );
	}

	function latestPost() {
		return hasOneThrough( [ "users", "posts" ] ).latest();
	}

	function tags() {
		return hasManyThrough( [ "users", "posts", "tags" ] ).distinct();
	}

	function comments() {
		return hasManyThrough( [ "users", "posts", "comments" ] ).where( "designation", "public" );
	}

	function commentsUsingHasManyThrough() {
		return hasManyThrough( [ "posts", "comments" ] ).where( "designation", "public" );
	}

	function roles() {
		return hasManyThrough( [ "users", "roles" ] );
	}

	function permissions() {
		return hasManyThrough( [ "roles", "permissions" ] );
	}

	function keyType() {
		return variables._wirebox.getInstance( "UUIDKeyType@quick" );
	}

}
