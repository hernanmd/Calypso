tests
testItemsWhereConditionIsTrue

	self buildResultWith: #(#item1 #item2 #item3 #item4).
	
	items := queryResult itemsWhere: [:each | #(item2 item3) includes: each actualObject].
	
	self assert: items size equals: 2.
	self assert: items first actualObject equals: #item2.
	self assert: items first position equals: 2.
	self assert: items second actualObject equals: #item3.
	self assert: items second position equals: 3