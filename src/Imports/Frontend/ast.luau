-- This module is for exporting types for the parser

export type NodeType =
	-- Statements
	| "Program"
	| "VarDeclaration"
	| "FunctionDeclaration"
	| "WhileLoop"
	| "ForLoop"
	| "IfStatement"
	| "BreakStatement"
	-- Expressions
	| "CommentExpr"
	| "AssignmentExpr"
	| "MemberExpr"
	| "CallExpr"
	| "FunctionExpr"
	| "ReturnExpr"
	-- Literals
	| "Property"
	| "ObjectLiteral"
	| "NumericLiteral"
	| "StringLiteral"
	| "Identifier"
	| "BinaryExpr"

export type Stmt = { -- Statement
	kind: NodeType
}

export type Program = Stmt & {
	kind: "Program",

	body: {Stmt},
	isAstInterface: boolean
}

export type VarDeclaration = Stmt & {
	kind: "VarDeclaration",

	constant: boolean,
	identifier: string,
	value: Expr
}

export type FunctionDeclaration = Stmt & {
	kind: "FunctionDeclaration",

	name: string,
	parameters: {string},
	body: Stmt
}

export type WhileLoop = Stmt & {
	kind: "WhileLoop",

	condition: ConditionalExpr,
	body: {Stmt}
}

export type ForLoop = Stmt & {
	kind: "ForLoop",

	identifier: string,
	startIndex: Expr,
	endIndex: Expr,
	body: {Stmt}
}

export type IfStatement = Stmt & {
	kind: "IfStatement",

	condition: ConditionalExpr,
	body: {Stmt},
	elseBody: {Stmt}?
}

export type BreakStatement = Stmt & {
	kind: "BreakStatement",
}

export type Expr = Stmt & {
	kind: string
}

export type BinaryExpr = Expr & {
	kind: "BinaryExpr",

	left: Expr,
	right: Expr,
	operator: string
}

export type CommentExpr = Expr & {
	kind: "CommentExpr",
	
	comment: string
}

export type AssignmentExpr = Expr & {
	kind: "AssignmentExpr",
	
	assignee: Expr,
	value: Expr
}

export type ConditionalExpr = Expr & {
	kind: "ConditionalExpr",

	left: Expr,
	right: Expr,
	operator: string
}

export type MemberExpr = Expr & {
	kind: "MemberExpr",

	object: Expr,
	property: Expr,
	isComputed: boolean -- computed memberexprs are object[property], while non-computed are object.property
}

export type FunctionExpr = Stmt & { -- these are functions without the name (ex. "function() end") instead of "function hi() end"
	kind: "FunctionDeclaration",
	
	parameters: {string},
	body: Stmt
}

export type ReturnExpr = Expr & {
	kind: "CallExpr",

	value: Expr,
}

export type CallExpr = Expr & {
	kind: "CallExpr",

	base: Expr,
	args: {Expr},
}

export type Identifier = Expr & {
	kind: "Identifier",
	
	symbol: string
}

export type NumericLiteral = Expr & {
	kind: "NumericLiteral",
	
	value: number
}

export type StringLiteral = Expr & {
	kind: "StringLiteral",

	value: string
}

export type Property = Expr & {
	kind: "Property",

	key: string,
	value: Expr
}

export type ObjectLiteral = Expr & {
	kind: "ObjectLiteral",

	properties: {Property}
}

return nil
