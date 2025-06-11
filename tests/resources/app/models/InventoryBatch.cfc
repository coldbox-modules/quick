component table="inventory_batches" extends="quick.models.BaseEntity" accessors="true" {

    property name="id";

    function scopeAddTradeCount( qb ) {
        qb.selectRaw(" (SELECT count(id) FROM trades WHERE trades.inventoryBatchId = inventory_batches.id) as tradeCount");
        appendVirtualAttribute( "tradeCount" );
    }

}