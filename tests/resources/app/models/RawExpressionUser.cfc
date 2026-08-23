component extends="User" table="users" accessors="true" {

	public any function tableSource( required any builder ) {
		return arguments.builder.raw( "users FORCE INDEX (PRIMARY)" );
	}

}
