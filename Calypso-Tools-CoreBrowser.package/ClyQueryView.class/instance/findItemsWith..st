queries
findItemsWith: actualObjects

	^self findAllItemsBy: [ :ds | | result |
		result := ds findItemsWith: actualObjects.
		result size = actualObjects size ifTrue: [ 
			"if all items were found then we are done. No need to continue full lookup"
			^result ]]