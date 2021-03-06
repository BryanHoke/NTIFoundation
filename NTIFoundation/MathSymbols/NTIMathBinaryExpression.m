//
//  NTIMathBinaryExpression.m
//  NTIFoundation
//
//  Created by Pacifique Mahoro on 4/11/12.
//  Copyright (c) 2012 NextThought. All rights reserved.
//

#import "NTIMathBinaryExpression.h"
#import "NTIMathPlaceholderSymbol.h"
#import "NTIMathOperatorSymbol.h"
#import "NTIMathExponentBinaryExpression.h"
#import "NTIMathFractionBinaryExpression.h"
#import "NTIMathUnaryExpression.h"
#import "NTIMathAlphaNumericSymbol.h"

@interface NTIMathBinaryExpression() 
//-(NSUInteger)precedenceLevelForString: (NSString *)opString;
-(NTIMathSymbol *)addAsChildMathSymbol: (NTIMathSymbol *)newMathSymbol;
@end

@implementation NTIMathBinaryExpression
@synthesize leftMathNode, rightMathNode, operatorMathNode, isOperatorImplicit, implicitForSymbol;

+(NTIMathBinaryExpression *)binaryExpressionForString:(NSString *)symbolString
{
	if ([symbolString isEqualToString:@"+"]) {
		return [[NTIMathAdditionBinaryExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"-"]) {
		return [[NTIMathSubtractionBinaryExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"^"]) {
		return [[NTIMathExponentBinaryExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"*"]) {
		return [[NTIMathMultiplicationBinaryExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"/"]	) {
		return [[NTIMathFractionBinaryExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"÷"]) {
		return [[NTIMathDivisionBinaryExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"="]	) {
		return [[NTIMathEqualityExpression alloc] init];
	}
	if ([symbolString isEqualToString:@"≈"]) {
		return [[NTIMathApproxExpression alloc] init];
	}
	
	OBASSERT_NOT_REACHED(@"%@ not supported", symbolString);
	return nil;
}

-(id)initWithMathOperatorSymbol: (NSString *)operatorString
{
	self = [super init];
	if (self) {
		self->operatorMathNode = [[NTIMathOperatorSymbol alloc] initWithValue:operatorString];
		self->operatorMathNode.parentMathSymbol = self;
		self->leftMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		self->leftMathNode.parentMathSymbol = self;
		self->rightMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		self->rightMathNode.parentMathSymbol = self;
	}
	return self;
}

-(void)setLeftMathNode:(NTIMathSymbol *)aLeftMathNode
{
	self->leftMathNode = aLeftMathNode;
	self->leftMathNode.parentMathSymbol = self;
}

-(void)setRightMathNode:(NTIMathSymbol *)aRightMathNode
{
	self->rightMathNode = aRightMathNode;
	self->rightMathNode.parentMathSymbol = self;
}

-(NSArray*)children
{
	if( !self.leftMathNode && !self.rightMathNode ){
		return nil;
	}
	NSMutableArray* array = [NSMutableArray array];
	if(self.leftMathNode){
		[array addObject: self.leftMathNode];
	}
	
	if(self.rightMathNode){
		[array addObject: self.rightMathNode];
	}
	
	return array;
}

//NOTE: NOT TO BE CONFUSED with -addSymbol, because this is only invoked in case we need to add something in between the parent node( self ) and its child( right child). We get to this case based on precedence level comparison
-(NTIMathSymbol *)addAsChildMathSymbol: (NTIMathSymbol *)newMathSymbol
{
	NTIMathSymbol* temp = self.rightMathNode;
	self.rightMathNode = newMathSymbol;
	
	//Then we take what was on the right node and move it down a level as a child of the new node.
	return [newMathSymbol addSymbol: temp];
}

#pragma mark - NTIMathExpressionSymbolProtocol Methods
-(BOOL)requiresGraphicKeyboard
{
	return [leftMathNode requiresGraphicKeyboard] && [rightMathNode requiresGraphicKeyboard];
}

-(NTIMathSymbol *)addSymbol:(NTIMathSymbol *)newSymbol
{
	//Stack it on the left
	if ([self.leftMathNode respondsToSelector:@selector(isPlaceholder)]){
		self.leftMathNode = newSymbol;
		//return self.rightMathNode;
	}
	else if (![self.leftMathNode respondsToSelector:@selector(isPlaceholder)] && [self.rightMathNode respondsToSelector:@selector(isPlaceholder)] ) {
		//Left full, right is placeholder
		self.rightMathNode = newSymbol;
		//return self.rightMathNode;
	}
	
	if ([self.leftMathNode respondsToSelector:@selector(isPlaceholder)]) {
		return self.leftMathNode;
	}
	else {
		if ([self.rightMathNode respondsToSelector:@selector(isBinaryOperator)]
			|| [self.rightMathNode respondsToSelector:@selector(isUnaryOperator)]) {
			return [self findLastLeafNodeFrom: self.rightMathNode];
		}
		return self.rightMathNode;
	}
	//return nil;
}

-(NTIMathSymbol *)swapNode: (NTIMathSymbol *)childNode withNewNode: (NTIMathSymbol *)newNode
{
	//NOTE: this function should only be used to swap an existing node with another non-placeholder node.
	if (self.leftMathNode == childNode) {
		self.leftMathNode = newNode;
		return self.leftMathNode;
	}
	else if (self.rightMathNode == childNode){
		self.rightMathNode = newNode;
		return self.rightMathNode;
	}
	
	OBASSERT_NOT_REACHED(@"child node: %@ is not one of our children nodes", childNode);
	return nil;
}

-(void)replaceNode: (NTIMathSymbol *)newMathNode withPlaceholderFor: (NTIMathSymbol *)pointingTo
{
	//Replace child node with a placeholder
	if (self.leftMathNode == newMathNode) {
		self.leftMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		[(NTIMathPlaceholderSymbol *)self.leftMathNode setInPlaceOfObject: pointingTo];
		pointingTo.substituteSymbol = self.leftMathNode;
	}
	if (self.rightMathNode == newMathNode) {
		self.rightMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		[(NTIMathPlaceholderSymbol *)self.rightMathNode setInPlaceOfObject: pointingTo];
		pointingTo.substituteSymbol = self.rightMathNode;
	}
}

-(NTIMathSymbol *)deleteSymbol:(NTIMathSymbol *)mathSymbol
{
	//if we only have placeholders
	if ( [self.leftMathNode respondsToSelector:@selector(isPlaceholder)] && [self.rightMathNode respondsToSelector:@selector(isPlaceholder)] ) {
		return nil;
	}
	
	if ([mathSymbol respondsToSelector:@selector(isPlaceholder)]) {
		return nil;
	}
	if (self.leftMathNode == mathSymbol) {
		self.leftMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		return self.leftMathNode;
	}
	if (self.rightMathNode == mathSymbol) {
		self.rightMathNode = [[NTIMathPlaceholderSymbol alloc] init];
		return self.rightMathNode;
	}
	return nil;
}

static NTIMathSymbol* mathExpressionForSymbol(NTIMathSymbol* mathSymbol)
{
	return [NTIMathSymbol followIfPlaceholder: mathSymbol];
}

-(NSString *)toStringValueForChildNode: (NTIMathSymbol *)childExpression
{
	NSString* childStringValue = [childExpression toString];
	childExpression = mathExpressionForSymbol(childExpression);
	if ([[childExpression class] precedenceLevel] < [[self class] precedenceLevel] && ([[childExpression class] precedenceLevel] > 0)) {
		childStringValue = [NSString stringWithFormat: @"(%@)", childStringValue]; 
	}
	return childStringValue;
}

-(NTIMathSymbol *)findLastLeafNodeFrom: (NTIMathSymbol *)mathSymbol
{
	if ([mathSymbol respondsToSelector:@selector(isPlaceholder)] ||
		[mathSymbol respondsToSelector:@selector(isLiteral) ]) {
//		if ([mathSymbol respondsToSelector:@selector(inPlaceOfObject)]) {
//			NTIMathSymbol* representing = [mathSymbol performSelector:@selector(inPlaceOfObject)];
//			if (representing) {
//				return [self findLastLeafNodeFrom:representing];
//			}
//		}
		return mathSymbol;
	}
	else{
		if ([mathSymbol respondsToSelector:@selector(isBinaryOperator)]) {
			NTIMathBinaryExpression* bMathSymbol = (NTIMathBinaryExpression *)mathSymbol;
			return [self findLastLeafNodeFrom: bMathSymbol.rightMathNode];
		}
		if ([mathSymbol respondsToSelector:@selector(isUnaryOperator)]) {
			NTIMathUnaryExpression* uMathSymbol = (NTIMathUnaryExpression *)mathSymbol;
			return [self findLastLeafNodeFrom: uMathSymbol.childMathNode];
		}
		return nil;
	}
}

//Adds parenthesis, if they need to be added.
-(NSString *)latexValueForChildNode: (NTIMathSymbol *)childExpression
{
	NSString* childLatexValue = [childExpression latexValue];
	childExpression = mathExpressionForSymbol(childExpression);
	if ([[childExpression class] precedenceLevel] < [[self class] precedenceLevel] && ([[childExpression class] precedenceLevel] > 0)) {
		childLatexValue = [NSString stringWithFormat: @"(%@)", childLatexValue]; 
	}
	return childLatexValue;
}

-(NSString *)toString
{
	NSString* leftNodeString = [self toStringValueForChildNode: self.leftMathNode];
	NSString* rightNodeString = [self toStringValueForChildNode: self.rightMathNode];
	
	//If it's implicit we will ignore the operator symbol.
	if (self.isOperatorImplicit) {
		return [NSString stringWithFormat:@"%@%@%@", leftNodeString, self.implicitForSymbol ? self.implicitForSymbol.toString : @"" ,rightNodeString];
	}
	NSString* string = [NSString stringWithFormat: @"%@%@%@", leftNodeString, [self.operatorMathNode toString], rightNodeString];
	return string;
}

-(NSString *)latexValue 
{
	//FIXME terrible hack here for mixed numbers
	BOOL showImplicitForSymbol = YES;
	if(	  self.isOperatorImplicit
	   && [[self.operatorMathNode toString] isEqualToString: @"+"]
	   && [mathExpressionForSymbol(self.leftMathNode) respondsToSelector: @selector(isLiteral)]
	   && [mathExpressionForSymbol(self.rightMathNode) isKindOfClass: [NTIMathDivisionBinaryExpression class]]){
		showImplicitForSymbol = NO;
	}
	
	showImplicitForSymbol = showImplicitForSymbol && self.implicitForSymbol;
	
	NSString* leftNodeString = [self latexValueForChildNode: self.leftMathNode];
	NSString* rightNodeString = [self latexValueForChildNode: self.rightMathNode];
	
	//If it's implicit we will ignore the operator symbol.
	if (self.isOperatorImplicit) {
		return [NSString stringWithFormat:@"%@%@%@", leftNodeString, showImplicitForSymbol ? self.implicitForSymbol.latexValue : @"" ,rightNodeString];
	}
	NSString* operatorString = [self.operatorMathNode latexValue];
	NSString* latexVal = [NSString stringWithFormat: @"%@%@%@", leftNodeString, operatorString, rightNodeString];
	return latexVal;
}

-(NSArray *)nonEmptyChildren
{
	NSMutableArray* neChildren = [NSMutableArray array];
	//not a placeholder, or it's a placeholder pointing to a subtree.
	if (![self.leftMathNode respondsToSelector:@selector(isPlaceholder)] || mathExpressionForSymbol(self.leftMathNode) != self.leftMathNode) {
		[neChildren addObject: self.leftMathNode];
	}
	if (![self.rightMathNode respondsToSelector:@selector(isPlaceholder)] || mathExpressionForSymbol(self.rightMathNode) != self.rightMathNode) {
		[neChildren addObject: self.rightMathNode];
	}
	return neChildren;
}

-(BOOL)isBinaryOperator
{
	return YES;
}
@end

@implementation NTIMathMultiplicationBinaryExpression

+(NSUInteger)precedenceLevel
{
	return 50;
}


-(id)init
{
	self = [super initWithMathOperatorSymbol: @"*"];
	if (self) {
	}
	return self;
}

@end


@implementation NTIMathEqualityExpression

-(id)init
{
	self = [super initWithMathOperatorSymbol: @"="];
	if (self) {
	}
	return self;
}

@end

@implementation NTIMathApproxExpression

-(id)init
{
	self = [super initWithMathOperatorSymbol: @"≈"];
	if (self) {
	}
	return self;
}

//This needs refactoring
-(NSString*)latexValue
{
	//FIXME terrible hack here for mixed numbers
	BOOL showImplicitForSymbol = YES;
	if(	  self.isOperatorImplicit
	   && [[self.operatorMathNode toString] isEqualToString: @"+"]
	   && [mathExpressionForSymbol(self.leftMathNode) respondsToSelector: @selector(isLiteral)]
	   && [mathExpressionForSymbol(self.rightMathNode) isKindOfClass: [NTIMathDivisionBinaryExpression class]]){
		showImplicitForSymbol = NO;
	}
	
	showImplicitForSymbol = showImplicitForSymbol && self.implicitForSymbol;
	
	NSString* leftNodeString = [self latexValueForChildNode: self.leftMathNode];
	NSString* rightNodeString = [self latexValueForChildNode: self.rightMathNode];
	
	//If it's implicit we will ignore the operator symbol.
	if (self.isOperatorImplicit) {
		return [NSString stringWithFormat:@"%@%@%@", leftNodeString, showImplicitForSymbol ? self.implicitForSymbol.latexValue : @"" ,rightNodeString];
	}
	NSString* operatorString = @"\\approx";
	NSString* latexVal = [NSString stringWithFormat: @"%@%@%@", leftNodeString, operatorString, rightNodeString];
	return latexVal;
}

@end

@implementation NTIMathAdditionBinaryExpression

+(NSUInteger)precedenceLevel
{
	return 40;
}


-(id)init
{
	self = [super initWithMathOperatorSymbol: @"+"];
	if (self) {
	}
	return self;
}

-(NSString *)toString
{
	if (self.isOperatorImplicit) {
		NSString* leftChildString = [self toStringValueForChildNode: self.leftMathNode];
		NSString* rightChildString = [self toStringValueForChildNode: self.rightMathNode];
		return [NSString stringWithFormat:@"%@ %@", leftChildString, rightChildString];
	}
	else {
		return [super toString];
	}
}
@end

@implementation NTIMathSubtractionBinaryExpression

+(NSUInteger)precedenceLevel
{
	return 40;
}

-(id)init
{
	self = [super initWithMathOperatorSymbol: @"-"];
	if (self) {
	}
	return self;
}
@end

@implementation NTIMathDivisionBinaryExpression

+(NSUInteger)precedenceLevel
{
	return 50;
}

-(id)init
{
	self = [super initWithMathOperatorSymbol: @"/"];
	if (self) {
	}
	return self;
}

-(NSString *)latexValue
{
	NSString* leftString = [self latexValueForChildNode: self.leftMathNode];
	NSString* rightString = [self latexValueForChildNode: self.rightMathNode];
	return [NSString stringWithFormat: @"\\frac{%@}{%@}", leftString, rightString]; 
}
@end


