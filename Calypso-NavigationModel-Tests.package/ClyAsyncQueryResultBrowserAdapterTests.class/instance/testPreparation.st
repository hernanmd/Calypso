running
testPreparation
	| newQuery newResult |
	newQuery := self createQuery.
	newResult := queryResult prepareNewFor: newQuery in: environment.
	
	self assert: newResult class equals: queryResult class.
	self deny: newResult == queryResult.
	self assert: newResult buildingQuery equals: (query async asyncResult: queryResult rawResult).
	self assert: newResult environment equals: environment.
	self assert: newResult needsRebuild.
	self assert: newResult isProtected.