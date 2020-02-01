Class {
	#name : #ClyBrowserSUnitIntegration,
	#superclass : #ClyMethodCodeEditorToolMorph,
	#traits : 'TClyGenerateTestClass',
	#classTraits : 'TClyGenerateTestClass classTrait',
	#instVars : [
		'testMethod',
		'testModel',
		'testMorph'
	],
	#category : #'Calypso-SystemPlugins-SUnitTestPane'
}

{ #category : #accessing }
ClyBrowserSUnitIntegration class >> browserTabActivation [
	"This declaration specifies that in any browser when methods are selected, a method editor will be available in a tab."
	
	<classAnnotation>
	^ClyTabActivationStrategy for: ClyMethod asCalypsoItemContext
]

{ #category : #accessing }
ClyBrowserSUnitIntegration class >> shouldBeActivatedInContext: aBrowserContext [

	^ true
]

{ #category : #accessing }
ClyBrowserSUnitIntegration class >> tabOrder [
	^ 1
]

{ #category : #updating }
ClyBrowserSUnitIntegration >> browserContextWasChanged [
	"We should ignore any notifications during applying changes 
	because applied changes can cause them which can lead to wrong recursive updates"
	applyingChanges ifNil: [ applyingChanges := false ].
	applyingChanges ifFalse: [ super browserContextWasChanged ]
]

{ #category : #building }
ClyBrowserSUnitIntegration >> build [
	super build.
	self methodClass isTestCase
		ifTrue: [ ^ self ].
	self buildTestMorph.
	testModel clearUndoManager.
	testMorph
		hResizing: #spaceFill;
		vResizing: #spaceFill.
	self addMorph: testMorph
]

{ #category : #building }
ClyBrowserSUnitIntegration >> buildTestMorph [
	testModel := RubScrolledTextModel new.
	testModel interactionModel: self.
	testMorph := testModel newScrolledText.
	testMorph
		width: self width; "build is performed in background when owner is not exist yet. But we need proper width to perform kind of styling/formatting if needed"
		beWrapped;
		font: StandardFonts codeFont;
		editingMode: self editingMode.
	CmdKMDispatcher attachedTo: testMorph textArea withCommandsFrom: self. "It overrides default text morph shortcuts with Commander"
"	self buildLeftSideBar."
	testMorph withTextSegmentIcons.
	testModel setInitialText: self testText.
]

{ #category : #'events handling' }
ClyBrowserSUnitIntegration >> changesAccepted [

	| applied |
	
	super changesAccepted.
	^self applyChangesBy: [ 
		testMorph hasUnacceptedEdits: true.
		[self changesAreAboutApply.
		applied := self applyChanges] on: Error do: [ :err | 
			testModel text: self editingText. 
			testMorph hasUnacceptedEdits: true.
			err pass].	
		applied 
			ifTrue: [ testMorph hasUnacceptedEdits: false. 
				self textUpdated.
				browser focusActiveTab ]
			ifFalse: [ 
				testModel text: self editingText. 
				testMorph hasUnacceptedEdits: true].
	]
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> formatSourceCode [

	super formatSourceCode.
	testMorph formatSourceCode 
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> formatTextIfNeeded [

	super formatTextIfNeeded.
	
	RBProgramNode formatterClass formatAsYouReadPolicy ifFalse: [ ^self].
	testMorph formatSourceCode. 
	testModel clearUserEdits
]

{ #category : #review }
ClyBrowserSUnitIntegration >> generateTestMethodFor: aMethod [
	" Private - Generate a test method for aMethod if not already present. Does not generate methods for classes ended with 'Test'  "
	[
		| testClass selector |

		testClass := self testClassFor: aMethod methodClass.
		selector := self testMethodNameFor: aMethod.
		(testClass includesSelector: selector) ifFalse: [ self generateTestMethodNamed: selector in: testClass ].
	
		testMethod := testClass >> selector 
	] 
	on: ClyInvalidClassForTestClassGeneration
	do: [ :ex | self inform: 'Impossible to create test class for ' , ex baseClass printString , '.' ]

]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> generateTestMethodNamed: aSymbol in: aClass [

	| body |
	body := '{1}

	self flag: #toImplement.
	self assert: false' format: {aSymbol}.
	aClass compile: body classified: 'test'
]

{ #category : #updating }
ClyBrowserSUnitIntegration >> isSimilarTo: anotherBrowserTool [

	(super isSimilarTo: anotherBrowserTool) ifFalse: [ ^false ].
	
	^editingMethod == anotherBrowserTool editingMethod "or: 
		[ editingMethod selector == anotherBrowserTool editingMethod selector
			and: [ editingMethod origin == anotherBrowserTool editingMethod origin ] ]"
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> testClassFor: inputClass [
	| className resultClass sysEnv |
	
	sysEnv := ClySystemEnvironment currentImage.
	className := self testClassNameFor: inputClass.
	sysEnv
		classNamed: className
		ifPresent: [ :class | resultClass := class ]
		ifAbsent: [
			(self isValidClass: inputClass) ifFalse: [ ClyInvalidClassForTestClassGeneration signalFor: inputClass ].
			sysEnv ensureExistAndRegisterPackageNamed: inputClass package name asString , '-Tests'.
			resultClass := TestCase
				subclass: className
				instanceVariableNames: ''
				classVariableNames: ''
				package: (self newTestClassCategoryFor: inputClass).
			self addNewCommentForTestClass: resultClass basedOn: inputClass ].
	^ resultClass
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> testClassNameFor: inputClass [
	" Private - Answer a <Symbol> representing a test class. If inputClass is meta, use the same 'instance' test class for compiling the tests "

	^ (String streamContents: [ : stream | 
		stream 
			nextPutAll: (inputClass isMeta
				ifFalse: [ inputClass name ]
				ifTrue: [ (inputClass name findTokens: ' ') first ]);
			nextPutAll: 'Test' ]) asSymbol
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> testMethod [
	^ testMethod
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> testMethod: anObject [
	testMethod := anObject
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> testMethodNameFor: aMethod [
	^ (String
		streamContents: [ :s | 
			s nextPutAll: 'test'.
			(aMethod selector splitOn: $:) do: [ :each | s nextPutAll: each capitalized ] ]) asSymbol
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> testModel [
	^ testModel
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> testModel: anObject [
	testModel := anObject
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> testMorph [
	^ testMorph
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> testMorph: anObject [
	testMorph := anObject
]

{ #category : #accessing }
ClyBrowserSUnitIntegration >> testText [

	self generateTestMethodFor: self editingMethod.
	^ testMethod sourceCode
]

{ #category : #updating }
ClyBrowserSUnitIntegration >> update [
	| unacceptedText newText |
	
	super update.
	newText := self editingText.
	self pendingText asString = newText ifTrue: [ 
		self applyDecorations.
		^self ].

	self hasUnacceptedEdits ifTrue: [unacceptedText := self pendingText copy].
	testModel setInitialText: newText.
	unacceptedText ifNil: [ ^self textUpdated ].

	self pendingText: unacceptedText.
	testMorph hasEditingConflicts: true.
	testMorph changed
]
