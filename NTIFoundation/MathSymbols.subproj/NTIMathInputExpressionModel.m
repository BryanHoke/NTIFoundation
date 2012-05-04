//
//  NTIMathInputExpressionModel.m
//  NTIFoundation
//
//  Created by  on 4/26/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathInputExpressionModel.h"
#import "NTIMathSymbol.h"
#import "NTIMathAbstractBinaryCombiningSymbol.h"
#import "NTIMathPrefixedSymbol.h"
#import "NTIMathPlaceholderSymbol.h"
#import "NTIMathAlphaNumericSymbol.h"
#import "NTIMathOperatorSymbol.h"
#import "NTIMathExponentCombiningBinarySymbol.h"
#import "NTIMathParenthesisSymbol.h"
#import "NTIMathFractionCombiningBinarySymbol.h"

@interface NSString(mathSymbolExtension)
-(BOOL)isOperatorSymbol;
-(BOOL)isAlphaNumeric;
-(BOOL)isMathPrefixedSymbol;
-(BOOL)isMathBinaryCombiningSymbol;
@end

@implementation NSString(mathSymbolExtension)

-(BOOL)isOperatorSymbol
{
	NSArray* array = [[NSArray alloc] initWithObjects: @"=", nil];
	return [array containsObject: self];
}

-(BOOL)isAlphaNumeric
{
	NSString* regex = @"^[a-zA-Z0-9]*$|^\\.$";	//count alphanumeric plus a dot(.)
	NSPredicate* regexTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	return [regexTest evaluateWithObject: self];
}

-(BOOL)isMathPrefixedSymbol
{
	//The list will grow as we support more symbols
	NSArray* array = [[NSArray alloc] initWithObjects: @"∫", @"√", nil];
	return [array containsObject: self];
}

-(BOOL)isParanthesisSymbol
{
	NSArray* array = [[NSArray alloc] initWithObjects: @"(", @")", nil];
	return [array containsObject: self];
}

-(BOOL)isMathBinaryCombiningSymbol
{
	//The list will grow as we support more symbols
	NSArray* array = [[NSArray alloc] initWithObjects:@"^",@"/", @"+", @"-", @"*", @"÷", @"x/y", nil];
	return [array containsObject: self];
}

@end

@interface NTIMathInputExpressionModel()
-(NTIMathSymbol *)addMathNode: (NTIMathSymbol *)newNode on: (NTIMathSymbol *)currentNode;
-(NTIMathSymbol *)createMathSymbolForString: (NSString *)stringValue;
-(void)logCurrentAndRootSymbol;
-(NTIMathSymbol *)closeAndAppendTree;
//returns the new current symbol after performing deletion
-(NTIMathSymbol *)deleteMathsymbol: (NTIMathSymbol *)aMathNode;
@end

@implementation NTIMathInputExpressionModel
//@synthesize mathInputModel;

-(id)initWithMathSymbol:(NTIMathSymbol *)mathExpression
{
	self = [super init];
	if (self) {
		if (!mathExpression) {
			mathExpression = [[NTIMathPlaceholderSymbol alloc] init];
		}
		//self.mathInputModel = mathExpression;
		self->rootMathSymbol = mathExpression;
		self->currentMathSymbol = mathExpression;
		self->stackEquationTrees = [NSMutableArray array];
	}
	return self;
}

-(void)addMathSymbolForString: (NSString *)stringValue
{
	NTIMathSymbol* newSymbol = [self createMathSymbolForString:stringValue];
	if (!newSymbol) {
		return;
	}
#if 0
	[self logCurrentAndRootSymbol];
#endif
	//Check if it's a special case of implicit multiplication. In which case, we will need to add
	if ([self->currentMathSymbol respondsToSelector:@selector(isLiteral)] && [newSymbol respondsToSelector:@selector(isUnaryOperator)]) {
		NTIMathSymbol* implicitSymbol = [self createMathSymbolForString:@"*"];
		self->currentMathSymbol = [self addMathNode:implicitSymbol on: self->currentMathSymbol];
	}
	self->currentMathSymbol = [self addMathNode: newSymbol on: self->currentMathSymbol];
#if 0
	[self logCurrentAndRootSymbol];
#endif
}

#pragma mark -- Handling and building the equation model
//Creating a new tree
-(NTIMathSymbol *)newMathSymbolTreeWithRoot: (NTIMathSymbol *)newRootSymbol 
								 firstChild: (NTIMathSymbol *)childSymbol
{
	if (!newRootSymbol) {
		NTIMathSymbol* placeHolder = [[NTIMathPlaceholderSymbol alloc] init];
		[self->stackEquationTrees addObject: self->rootMathSymbol];
		self->rootMathSymbol = placeHolder;
		return self->rootMathSymbol; //it's the current symbol as well.
	}
	else {
		//This a special case when a user clicks on an element of the tree, we start a new tree at that element, and we set it as a root element. No child at this point.
		if (newRootSymbol && !childSymbol) {
			NTIMathSymbol* parent = newRootSymbol.parentMathSymbol;
			if ([parent respondsToSelector: @selector(replaceNode:  withPlaceholderFor:)]) {
				//We remove it from its parent
				[parent performSelector: @selector(replaceNode:  withPlaceholderFor:) withObject: newRootSymbol withObject: newRootSymbol];
				//Add current root to stack
				[self->stackEquationTrees addObject: self->rootMathSymbol];
				//Set new root 
				self->rootMathSymbol = newRootSymbol;
				self->rootMathSymbol.parentMathSymbol = nil;
				//Add the childsymbol to new root
				return self->rootMathSymbol;
			}
		}	
		if (childSymbol.parentMathSymbol) {
			NTIMathSymbol* parent = childSymbol.parentMathSymbol;
			if ([parent respondsToSelector: @selector(replaceNode:  withPlaceholderFor:)]) {
				//We remove it from its parent
				[parent performSelector: @selector(replaceNode:  withPlaceholderFor:) withObject: childSymbol withObject: newRootSymbol];
				//Add current root to stack
				[self->stackEquationTrees addObject: self->rootMathSymbol];
				
				//Set new root 
				self->rootMathSymbol = newRootSymbol;
				//self->rootMathSymbol.parentMathSymbol = nil;
				//Add the childsymbol to new root
				return [self->rootMathSymbol addSymbol: childSymbol];
			}
		}
		else {
			//No parent
			//Set new root to be the root symbol
			self->rootMathSymbol = newRootSymbol;
			if ([newRootSymbol respondsToSelector:@selector(isLiteral)]) {
				return self->rootMathSymbol;
			}
			
			//Add as first child the childsymbol
			return [self->rootMathSymbol addSymbol: childSymbol];
		}
	}
	return nil;
}

-(NTIMathSymbol *)findRootOfMathNode: (NTIMathSymbol *)mathSymbol
{
	while (mathSymbol.parentMathSymbol) {
		mathSymbol = mathSymbol.parentMathSymbol;
	}
	return mathSymbol;
}

//We want to traverse the tree from the top to bottom.
-(void)addPlaceholdersWithExpressionTo: (NSMutableArray *)placeholders fromMathNode: (NTIMathSymbol *)aRootNode
{
	if (!aRootNode) {
		return;
	}
	if (!aRootNode.children) {
		if ( [aRootNode respondsToSelector:@selector(isPlaceholder)] && 
			[(NTIMathPlaceholderSymbol *)aRootNode inPlaceOfObject] ) {
			[placeholders addObject: aRootNode];
		}
		return;
	}
	for (NTIMathSymbol* child in aRootNode.children) {
		[self addPlaceholdersWithExpressionTo: placeholders fromMathNode: child];
	}
}

//We return the currentSymbol
-(NTIMathSymbol *)closeAndAppendTree
{	
	//Pop the top most item off the tree stack
	NTIMathSymbol* oldRootSymbol = [self->stackEquationTrees lastObject];
	if (oldRootSymbol) {
		//remove the last object 
		[self->stackEquationTrees removeLastObject];
		NTIMathSymbol* tempCurrentSymbol = self->rootMathSymbol;	//Because we are done adding things to this tree
		//We add the new rootMathSymbol to the tree.
		if (![oldRootSymbol addSymbol: self->rootMathSymbol]) {
			//if we can't add it, that means we could be a placeholder, in which case we would simple replace it
			if ([oldRootSymbol respondsToSelector:@selector(isPlaceholder)]) {
				oldRootSymbol = self->rootMathSymbol;
			}
		}
		self->rootMathSymbol = oldRootSymbol;
		//the current symbol should becomes the root symbol.
		return tempCurrentSymbol;
	}
	return  nil;
}

-(NTIMathSymbol *)replacePlaceHolder: (NTIMathSymbol *)pholder withLiteral: (NTIMathSymbol *)literal
{
	if (![pholder respondsToSelector:@selector(isPlaceholder)] ||
		![literal respondsToSelector:@selector(isLiteral)]) {
		return nil;
	}
	
	if (pholder.parentMathSymbol) {
		// Add literal to replace pholder
		return [pholder.parentMathSymbol addSymbol: literal];
	}
	else {
		//a pholder is the root element
		self->rootMathSymbol = literal;
		return literal;
	}
	return nil;
}

-(NTIMathPlaceholderSymbol *)placeholderLinkFor:(NTIMathSymbol *)mathSymbol inExpression: (NTIMathSymbol *)rootExpression
{
	NSMutableArray* placeholders = [NSMutableArray array];
	[self addPlaceholdersWithExpressionTo: placeholders fromMathNode: rootExpression];
	for (NTIMathPlaceholderSymbol* pholder in placeholders) {
		if ([pholder inPlaceOfObject] == mathSymbol) {
			return pholder;
		}
	}
	return nil;
}

//In case of delete, trivial case in case of delete
-(NTIMathSymbol *)placeholderReplaceLiteral: (NTIMathAlphaNumericSymbol *)literal
{
	NTIMathSymbol* parent = literal.parentMathSymbol;
	if (parent) {
		return [parent deleteSymbol: literal];
	}
	else {
		//we don't have a parent, so the literal must be the root symbol,
		OBASSERT(self->rootMathSymbol == literal);
		self->rootMathSymbol = [[NTIMathPlaceholderSymbol alloc] init];
		
		//if we have a stack of trees, update the placeholder that was pointing to the literal
		if ([self->stackEquationTrees count] > 0) {
			NTIMathSymbol* oldRoot = [self->stackEquationTrees lastObject];
			NTIMathPlaceholderSymbol* placeholder = [self placeholderLinkFor:literal inExpression:oldRoot];
			if (placeholder) {
				placeholder.inPlaceOfObject = self->rootMathSymbol;
				return self->rootMathSymbol;
			}
		}
		
		
		return self->rootMathSymbol;
	}
}

-(NTIMathSymbol *)addMathNode: (NTIMathSymbol *)newNode on: (NTIMathSymbol *)currentNode
{
	// Paranthesis
	if ([newNode respondsToSelector:@selector(openingParanthesis)]) {
		if( [newNode performSelector:@selector(openingParanthesis)] ) {
			//Make a new tree
			return [self newMathSymbolTreeWithRoot: nil firstChild: nil];
		}
		else {
			//close and append tree --> closing paranthesis
			return [self closeAndAppendTree];
		}
	}
	
	//See if we can append it
	if ([currentNode respondsToSelector: @selector(appendMathSymbol:)] && 
		[newNode respondsToSelector:@selector(isLiteral)]) {
		return [currentNode performSelector:@selector(appendMathSymbol:) withObject: newNode];
	}
	
	//Replace pholder with literal.
	NTIMathSymbol* num = [self replacePlaceHolder: currentNode withLiteral: newNode];
	if (num) {
		return num;
	}
	
	while ( currentNode.parentMathSymbol ) {
		// look ahead
		// Rule 1: if our parent's precedence is lower, we make a new tree at current.
		if ( [currentNode.parentMathSymbol precedenceLevel] < [newNode precedenceLevel] ) {		
			//Make new tree with currentNode as a childNode to newNode. Basically swapping them.
			return [self newMathSymbolTreeWithRoot: newNode firstChild: currentNode];		
		}
		// Rule 2: if our parent's precedence is higher or equal to the new node's precedence:
		//			move up ( repeat process )
		currentNode = currentNode.parentMathSymbol;
	}
	
	if (currentNode.parentMathSymbol == nil) {
		//Make a new tree with root as newNode
		return [self newMathSymbolTreeWithRoot: newNode firstChild: currentNode];
	}
	return nil;
}

-(NSString *)generateEquationString
{
	return [[self fullEquation] toString];
}

-(NTIMathSymbol *)fullEquation
{
	if (!stackEquationTrees || stackEquationTrees.count == 0) {
		return self->rootMathSymbol;
	}
	NTIMathSymbol* oldRootSymbol;
	for (int i = stackEquationTrees.count-1;  i>= 0; i--) {
		//Update plaholders pointing to math expressions( trees)
		oldRootSymbol = [self->stackEquationTrees objectAtIndex:i];
		NSMutableArray* placeholders = [NSMutableArray array];
		[self addPlaceholdersWithExpressionTo: placeholders fromMathNode: oldRootSymbol];
		for (NTIMathPlaceholderSymbol* pholder in placeholders) {
			//The logic is that as we add things, the root changes and we need to update the pointer of the placeholder to the new root.
			NTIMathSymbol* replacedExpression= [pholder inPlaceOfObject];
			if (replacedExpression) {
				pholder.inPlaceOfObject = [self findRootOfMathNode: replacedExpression];
			}
		}
	}
	return oldRootSymbol;
}

-(void)setCurrentSymbolTo: (NTIMathSymbol *)mathSymbol
{
	//Needs to be implemented better. go through the math expression tree to find our node
	self->currentMathSymbol = [self newMathSymbolTreeWithRoot:mathSymbol firstChild: nil]; 
	//self->currentMathSymbol = mathSymbol;
}

-(void)clearEquation
{
	NTIMathSymbol* pholder = [[NTIMathPlaceholderSymbol alloc] init];
	self->rootMathSymbol= pholder;
	self->currentMathSymbol = pholder;
	[self->stackEquationTrees removeAllObjects];
}

-(void)deleteMathExpression: (NTIMathSymbol *)aMathSymbol
{
	if (!aMathSymbol) {
		//if nothing is selected, we assume the user wants to delete the current symbol
		aMathSymbol = self->currentMathSymbol;
	}
	self->currentMathSymbol = [self deleteMathsymbol: aMathSymbol];
}

//Return new current symbol
-(NTIMathSymbol *)switchTotreeInplaceOfPlaceholder: (NTIMathSymbol *)aMathSymbol;
{
	if ([aMathSymbol respondsToSelector:@selector(isPlaceholder)] && self->rootMathSymbol == aMathSymbol && self->stackEquationTrees.count > 0) {
		//We will pop the last tree off the stackTree
		self->rootMathSymbol = [self->stackEquationTrees lastObject];
		[self->stackEquationTrees removeLastObject];
		
		//Now that we have the root symbol, we need to find the current symbol which is essentially the one that was holding a pointer to the placeholder we had.
		NSMutableArray* placeholders = [NSMutableArray array];
		[self addPlaceholdersWithExpressionTo: placeholders fromMathNode: self->rootMathSymbol];
		
		for (NTIMathPlaceholderSymbol* pholder in placeholders) {
			if (pholder.inPlaceOfObject == aMathSymbol) {
				//this our current symbol now,
				pholder.inPlaceOfObject = nil;
				return pholder;
			}
		}
	}
	return nil;
}

-(NTIMathSymbol *)findLastLeafNodeFrom: (NTIMathSymbol *)mathSymbol
{
	if ([mathSymbol respondsToSelector:@selector(isPlaceholder)] ||
		[mathSymbol respondsToSelector:@selector(isLiteral) ]) {
		return mathSymbol;
	}
	else{
		if ([mathSymbol respondsToSelector:@selector(isBinaryOperator)]) {
			NTIMathAbstractBinaryCombiningSymbol* bMathSymbol = (NTIMathAbstractBinaryCombiningSymbol *)mathSymbol;
			return [self findLastLeafNodeFrom: bMathSymbol.rightMathNode];
		}
		if ([mathSymbol respondsToSelector:@selector(isUnaryOperator)]) {
			NTIMathPrefixedSymbol* uMathSymbol = (NTIMathPrefixedSymbol *)mathSymbol;
			return [self findLastLeafNodeFrom: uMathSymbol.childMathNode];
		}
		return nil;
	}
}

-(NTIMathSymbol *)deleteAndReplace: (NTIMathSymbol *)aMathSymbol
{
	//These are special cases,
	if ([aMathSymbol.parentMathSymbol respondsToSelector:@selector(isBinaryOperator)] && [aMathSymbol respondsToSelector:@selector(isPlaceholder)]) {
		NTIMathAbstractBinaryCombiningSymbol* parentSymbol = (NTIMathAbstractBinaryCombiningSymbol *)aMathSymbol.parentMathSymbol;
		
		if (parentSymbol.rightMathNode == aMathSymbol && ![parentSymbol.leftMathNode respondsToSelector: @selector(isPlaceholder)] ) {
			//At this point, we know 3 things: our parent is a binary operator, the left node has some expression, and the right node is a placeholder/empty. We are going to ask the parent of our parent(grandpa), to replace our parent with the left child.
			NTIMathSymbol* leftNode = parentSymbol.leftMathNode;
			if (parentSymbol.parentMathSymbol) {
				[parentSymbol.parentMathSymbol deleteSymbol: parentSymbol];
				return [parentSymbol.parentMathSymbol addSymbol: leftNode];
			}
			else {
				//if our parent doesn't have a parent, by definition, it is the current root symbol
				OBASSERT(parentSymbol == self->rootMathSymbol);
				//so we will set the root symbol to be the leftNode;
				self->rootMathSymbol = leftNode;
				self->rootMathSymbol.parentMathSymbol = nil;
				if (self->stackEquationTrees.count > 0) {
					//update who is pointing to us
					NTIMathPlaceholderSymbol* placeHolderLink = [self placeholderLinkFor: parentSymbol inExpression: [self->stackEquationTrees lastObject]];
					placeHolderLink.inPlaceOfObject = leftNode;
				}
				return [self findLastLeafNodeFrom: self->rootMathSymbol]; // it also become the current symbol.
			}
		}
		else if(parentSymbol.leftMathNode == aMathSymbol && ![parentSymbol.rightMathNode respondsToSelector:@selector(isPlaceholder)]) {
			NTIMathSymbol* rightNode = parentSymbol.rightMathNode;
			if (parentSymbol.parentMathSymbol) {
				[parentSymbol.parentMathSymbol deleteSymbol: parentSymbol];
				return [parentSymbol.parentMathSymbol addSymbol: rightNode];
			}
			else {
				//if our parent doesn't have a parent, by definition, it is the current root symbol
				OBASSERT(parentSymbol == self->rootMathSymbol);
				//so we will set the root symbol to be the leftNode;
				self->rootMathSymbol = rightNode;
				self->rootMathSymbol.parentMathSymbol = nil;
				if (self->stackEquationTrees.count > 0) {
					//update who is pointing to us
					NTIMathPlaceholderSymbol* placeHolderLink = [self placeholderLinkFor: parentSymbol inExpression: [self->stackEquationTrees lastObject]];
					placeHolderLink.inPlaceOfObject = rightNode;
				}
				return [self findLastLeafNodeFrom: self->rootMathSymbol]; // it also become the current symbol.
			}
		}
	}
	return nil;
}

-(NTIMathSymbol *)deleteMathsymbol: (NTIMathSymbol *)aMathNode
{
	//Primo, if it's a number, see if we can delete the last digit
	NTIMathSymbol* newCurrentNode = nil;
	if ([aMathNode respondsToSelector:@selector(isLiteral)]) {
		newCurrentNode = [(NTIMathAlphaNumericSymbol *)aMathNode deleteLastLiteral];
		if (newCurrentNode) {
			return newCurrentNode;
		}
		
		//Replace with a placeholder
		newCurrentNode = [self placeholderReplaceLiteral: (NTIMathAlphaNumericSymbol *)aMathNode];
		if (newCurrentNode) {
			return newCurrentNode;
		}
	}
	while (aMathNode.parentMathSymbol) {
		NTIMathSymbol* parent = aMathNode.parentMathSymbol;
		newCurrentNode = [parent deleteSymbol: aMathNode];
		if (newCurrentNode) {
			return newCurrentNode;
		}
		
		//Check for special cases of delete and replace
		newCurrentNode = [self deleteAndReplace: aMathNode];
		if (newCurrentNode) {
			return newCurrentNode;
		}
		
		//If we couldn't delete it, ask the parent to delete us! They may be exceptions to this rule.
		aMathNode = parent;
	}
	
	if (!aMathNode.parentMathSymbol) {
		if (aMathNode == self->rootMathSymbol && [aMathNode respondsToSelector:@selector(isPlaceholder)] && self->stackEquationTrees.count > 0) {
			aMathNode = [self switchTotreeInplaceOfPlaceholder: aMathNode];
			if (aMathNode) {
				return [self deleteMathsymbol: aMathNode];
			}
		}
	}
	
	//if we couldn't delete it, we will return the node
	return nil;
}

//Override property
-(NTIMathSymbol *)mathInputModel
{
	return [self fullEquation];
}

#pragma mark - Building on a mathSymbol
-(NTIMathSymbol *)createMathSymbolForString: (NSString *)stringValue
{	
	if ( [stringValue isAlphaNumeric] ) {
		return [[NTIMathAlphaNumericSymbol alloc] initWithValue: stringValue];
	}
	if ( [stringValue isOperatorSymbol] ) {
		return [[NTIMathOperatorSymbol alloc] initWithValue: stringValue];
	}
	if ( [stringValue isParanthesisSymbol] ) {
		return [[NTIMathParenthesisSymbol alloc] initWithMathSymbolString: stringValue];
	}
	if ( [stringValue isMathPrefixedSymbol] ) {
		return [[NTIMathPrefixedSymbol alloc] initWithMathOperatorString: stringValue];
	}
	if ( [stringValue isMathBinaryCombiningSymbol] ) {
		if ([stringValue isEqualToString:@"^"]) {
			return [[NTIMathExponentCombiningBinarySymbol alloc] init];
		}
		if ([stringValue isEqualToString: @"x/y"]) {
			return [[NTIMathFractionCombiningBinarySymbol alloc] init];
		}
		return [[NTIMathAbstractBinaryCombiningSymbol alloc] initWithMathOperatorSymbol: stringValue];
	}
	return nil;
}

-(void)logCurrentAndRootSymbol
{
	NSLog(@"root's string: %@,\ncurrentSymbol's string: %@", [self->rootMathSymbol toString], [self->currentMathSymbol toString]);
}
@end
