# Andrew Hankewycz
# CMPEN 351
# Biomorphs
# Draws 9 random biomorphs to the display. The user is prompted to select 1 of the 9 to become the parent of the next generation.
# The parent biomorph breeds another 9 children which are again displayed to the screen and the cycle repeats. The program also includes
# an editor mode where the user can edit the genes manually to affect the biomorphs characteristics.


# variables go here
.data
stack:		.word 0:20	# make a 20 word stack
stackbot:	.word 0		# pointer right after stack
centerX:	.word 85, 255, 425, 85, 255, 425, 85, 255, 425, 	# parallel array with x coordinates in order
centerY:	.word 85, 85, 85, 255, 255, 255, 425, 425, 425, 	# parallel array with y coordinates in order
color:		.word 0xFFFFFF

numberOfGenes:	.word 10		# stores the number of genes
sizeOfArray:	.word 40	# this variable stores the length of a biomorph array currently

parent:		.word 	-10, -10, 0, -10, -5, -10, -5, 0, 4, 0


b0:		.word 	0, 0, 0, 0, 0, 0, 0, 0, 0, 0
b1:		.word 	0, 0, 0, 0, 0, 0, 0, 0, 0, 0
b2:		.word 	0, 0, 0, 0, 0, 0, 0, 0, 0, 0
b3:		.word 	0, 0, 0, 0, 0, 0, 0, 0, 0, 0
b4:		.word 	0, 0, 0, 0, 0, 0, 0, 0, 0, 0
b5:		.word 	0, 0, 0, 0, 0, 0, 0, 0, 0, 0
b6:		.word 	0, 0, 0, 0, 0, 0, 0, 0, 0, 0
b7:		.word 	0, 0, 0, 0, 0, 0, 0, 0, 0, 0
b8:		.word 	0, 0, 0, 0, 0, 0, 0, 0, 0, 0

# lookup table for array offset values for genes
tw:		  .word 0
bcw:		.word 4
baw:		.word 8
cbw:		.word 12
th:	  	.word 16
bah:		.word 20
cah:		.word 24
cbh:		.word 28
bch:		.word 32
nodes:  .word 36

# lookup table to map keypad to biomorph array
inputTable:	.word 6, 7, 8, 3, 4, 5, 0, 1, 2

selectPrompt:		.asciiz "Select new parent Biomorph\nOr 0 to enter Editor Mode\n"
invalidPrompt:		.asciiz "Invalid selection\n"
editorPrompt:		.asciiz "Please select the biomorph you would like to edit\n"
genePrompt:		.asciiz "Select which gene you would like to modify\n(1 2 3 4 5 6 7 8 9 10)\nWidth: genes 1-4, Height: genes 5-9, Depth: 10\nEnter 0 to submit changes as new Parent\n"
geneValPrompt:		.asciiz "Enter the value you would like to assign to this gene (-15 <= x <= 15)\n"
invalidGenePrompt:	.asciiz "That is an invalid gene selection\n"
invalidGeneValuePrompt:	.asciiz "The entered value is outside the acceptable range\n"
currentValPrompt:	.asciiz "Gene current value is "
db:			.asciiz "drawing a A\n"
dl:			.asciiz	"drawing Left\n"
dr:			.asciiz "drawing Right\n"

# code goes here
.text

la $sp, stackbot	# set stack pointer to the end of the stack
jal setupRandomGen


jal clearScreen		# clear screen incase anything is there
jal get9RandomBios
jal drawGrid
jal drawBiomorphs
mainLoop:

# select next Biomorph
la $a0, selectPrompt
jal getSelection
bnez $v0, skipEdit	# if the user did not select editor mode, skip past it
jal editorMode
skipEdit:
move $s0, $v0		# copy user input to s0
jal clearScreen
move $a0, $s0		# move slected biomorph from s0 to a0 for call
jal newParent
jal drawGrid
la $a0, parent
jal breedChildren
jal drawBiomorphs

j mainLoop

exit:

j end

# getSelection gets the number from the user as a biomorph selection
# expects: $a0 - address to prompt
# returns: $v0 - base address for selected biomorph
# regs used:
# $t0 - user input value corrected for biomorph ordering
# $t1 - size of a biomorph array
# $v0 -
getSelection:
li $v0, 4		# setup syscall to print string
syscall			# print prompt
li $v0, 5	# setup syscall to read int
syscall
bltz $v0, exit	# input was negative, invalid
bgt $v0, 9, invalid	# if entry was > 9
beqz $v0, skipConv	# 0 skips the lookup table for values and returns 0
addi $t0, $v0, -1	# subtract 1 from users entry to convert 1-9 tp 0-8 for offsetting
la $t1, inputTable	# load base address of inputTable
sll $t0, $t0, 2		# convert input to byte offset, i * 4........ I could just add this to the lookup table 
add $t1, $t1, $t0	# add offset value to table base address
lw $t0, 0($t1)		# get corrected input value from table
lw $t1, sizeOfArray	# load the number of bytes a biomorph array takes
mul $t0, $t0, $t1	# t0 = t0 * arraylenght, # of bytes for each biomorphs data array, this is the offset from the array base
la $v0, b0($t0)		# s0 stores base address of data array for biomorph selected by user
skipConv:
jr $ra

invalid:
li $v0, 4		# setup to print string
la $a0, invalidPrompt	# load invalid entry prompt
syscall
j getSelection	# go back to top


# editorMode allows the user to modify the genes associated with a biomorph
# prompts the user to select one of the 9 displayed biomorphs and then prompts them to make changes to its genes
# the modified biomorph will then be selected as the next parent
# expects: N/A
# returns: $v0 - base address to the modified biomorph array
# registers used:
# $s0 - stores base address of the users selected biomorph
# $s1 - gene offset value
editorMode:
addi $sp, $sp, -8	# make room for 2 words on stack
sw $ra, 4($sp)		# store return address on stack
sw $s0, 0($sp)		# store s0 on stack

la $a0, editorPrompt
jal getSelection	# this will not be good it the user enters an invalid entry, it will jump to the wrong place
move $s0, $v0		# store user selection in s0
jal clearScreen

prepDraw:
la $a0, centerX		# get x center array base addr
addi $a0, $a0, 16	# get x-cord of display center
lw $a0, 0($a0)		# get x-cord value
la $a1, centerY		# get y center array base 
addi $a1, $a1, 16	# get y-cord of display center
lw $a1, 0($a1)		# get y-cord value
move $a2, $s0		# copy base address of their selected biomorph to a2 for call
jal drawOrigin

askGene:
li $v0, 4
la $a0, genePrompt	# prompt for which gene they would like to modify
syscall
li $v0, 5		# setup to read int
syscall			# get gene selection from user

beqz $v0, exitEditLoop	# if the user enters 0, return to main loop
bgt $v0, 10, invalidGene	# if they enter greater than 15
bltz $v0,invalidGene	# if they enter less than -15

addi $s1, $v0, -1	# subtract 1 from user's gene to fix for offset
sll $s1, $s1, 2		# gene * 4 == offset

askValue:
li $v0, 4
la $a0, geneValPrompt	# prompt user to enter gene value between -15 and 15
syscall
la $a0, currentValPrompt	# load current value prompt
syscall

add $t0, $s0, $s1	# a0 = biomorph base address plus gene offset
lw $a0, 0($t0)		# load the specific genes current value to a0 for print
li $v0, 1		# setup to print int
syscall
li $a0, 0x0A		# new line char
li $v0, 11		# setup to print char
syscall

li $v0, 5
syscall			# read gene value from user, between -15 to 15	
bgt $v0, 15, invalidGeneValue	# if the user enters a value above 15
blt $v0, -15, invalidGeneValue	# if the user enters a value below -15

add $t0, $s0, $s1	# address to store new value = biomorph base address plus gene offset
sw $v0, 0($t0)		# store new value this biomorphs specific gene position
jal clearScreen
j prepDraw
exitEditLoop:

move $v0, $s0		# move the edited biomorphs base address to v0 as the address for the next parent
lw $s0, 0($sp)		# restore s0 from stack
lw $ra, 4($sp)		# restore return address from stack
addi $sp, $sp, 8	# pop 2 words from stack
jr $ra

invalidGene:
li $v0, 4
la $a0, invalidGenePrompt
syscall		# print message that the selected gene does not exist
j askGene	# go back and ask for which gene again

invalidGeneValue:
li $v0, 4
la $a0, invalidGeneValuePrompt
syscall			# print message that the entered gene value is out of range
j askValue		# return to asking for gene value


# clearScreen clears the bitmap display to all black
# expects: N/A
# returns: N/A
# registers used:
# $t0 - base address of display
# $t1 - total number of bytes in the display
# $t2 - value for black
clearScreen:
li $t0, 0x10040000	# load base address of display
li $t1, 0x00100000	# number of bytes needed to clear the display
add $t1, $t0, $t1	# t1 = display base + total bytes in display
li $t2, 0x00		# black
clearLoop:
sw $t2, 0($t0)		# store black at this pixel in display
addi $t0, $t0, 4	# move to next pixel
blt $t0, $t1, clearLoop	# if t0 < t1, branch
jr $ra

# draws all 9 biomorphs based on the data in the arrays
# expects: N/A
# returns: N/A
# registers used:
# $t0 - size of biomorph array
# $s0 - address to x-coordinate of biomorph center
# $s1 - address to y-coordinate of biomorph center
# $s2 - address to beginning of next biomorph array
# $s3 - counter for number of biomorphs to draw
# $a0 - passes x-cord to drawOrigin
# $a1 - passes y-cord to drawOrigin
# $a2 - passess bimorph array to drawOrigin
drawBiomorphs:
addi $sp, $sp, -20	# make room for 5 words on stack
sw $ra, 16($sp)		# store return address on stack
sw $s3, 12($sp)		# store s3 on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack

li $s3, 9		# counter for number of biomorphs to draw
la $s0, centerX		# load address to array of x coordinate center points
la $s1, centerY		# load address to array of y coordinate center points
la $s2, b0		# load address for first biomorphs data array

drawLoop:
lw $a0, 0($s0)		# load x coordinate value
lw $a1, 0($s1)		# load y coordinate value
move $a2, $s2		# copy starting address to bimorphs data array to a2 for call
jal drawOrigin		# drawBiomorph
addi $s3, $s3, -1	# decrement loop couter by 1
addi $s0, $s0, 4		# move to next center y coordinate
addi $s1, $s1, 4		# move to next center x coordinate
lw $t0, sizeOfArray		# load the number of bytes for a biomorph array
add $s2, $s2, $t0		# move to the next biomorphs data array
bgtz $s3, drawLoop	# loop until all 9 have been drawn

lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $s3, 12($sp)		# restore s3 from stack
lw $ra, 16($sp)		# restore return address from stack
addi $sp, $sp, 20	# pop 5 words from stack
jr $ra


# setupRandomGen sets up the PRG 0, seeding it with the system time
# expects: N/A
# returns: N/A
# registers used:
# $v0 - used for syscall
# $t0 - number for PRG I want to make
# $a0 - passes number for PRG
# $a1 - passes seed value for PRG
setupRandomGen:
li $v0, 30	# setup syscall to get lower 32-bits of system time
syscall		# get system time
move $t0, $a0	# copy lower 32 bits of system time to t0
li $a0, 0	# setup random gen 0
move $a1, $t0	# copy 32 bits of time to random seed register
li $v0, 40	# setup syscall to set random generator seed
syscall		# seed generator and create generator 0
jr $ra	# return to caller

# shouldMutate can be used to get a boolean value based on a percentage of time it should be true
# this can be used for determining if a gene should mutate or if the mutation should increase or decrease the gene
# expects: $a0 - value for percentage of times true (0-100)
# returns: $v0 1 if we need to mutate value, 0  if we do not need to mutate
# regs used:
# $v0 - boolean return value
# $t0 - % for mutation
# $a0 - number for which PRG to use
# $a1 - passes random number upper bound
shouldMutate:
add $t0, $0, $a0	# copy % rate passed in to t0
li $a0, 0	# load a0 with number of PRG, 0
li $a1, 99	# set upper bound to 99, range 0-99 inclusive
li $v0, 42	# setup syscall for generating random int
syscall		# get random int
addi $a0, $a0, 1	# add 1 to move range to 1-100
sle $v0, $a0, $t0	# if a0 <= % mutation rate, v0 = 1
jr $ra

# gets a random value between -10 and 10 to be used for generating a random biomorph
# expects: N/A
# returns: $v0 - random gene value between -10 & 10
# regs used:
# $v0 - returns random int
# $t0 - temp storage for random number
# $a0 - number for which PRG to use
# $a1 - random number upper bound
getRandomGene:
li $a0, 0	# load number of PRG
li $a1, 9	# load value of upper bound
li $v0, 42	# setup syscall to generate random int
syscall		# get random int
addi $a0, $a0, 1	# add 1 to shift range to 1-10
move $t0 $a0		# copy random into t0 for return
li $a0, 0	# load number of PRG
li $a1, 9	# load value of upper bound
li $v0, 42	# setup to generate another random int
syscall
bge $a0, 5, skipN	# if random int from 0-9 is >= 5, set value gene value negative
mul $t0, $t0, -1
skipN:
move $v0, $a0	# copy random gene value to v0 for return
jr $ra

# get9RandomBios gets 9 independently random biomorphs, this should be used at the beginning of the program to give the user a initial choice with more variablity
# expects: N/A
# returns: N/A
# regs used:
# $s0 - size of the biomorph array
# $s1 - address for the biomorph array
# $s2 - counter for number of biomorphs left to generate
# $a0 - passes address for current biomorph array
get9RandomBios:
addi $sp, $sp, -16	# make room on stack for 4 words
sw $ra, 12($sp)		# store return address on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack
lw $s0, sizeOfArray	# size of each biomorph array
la $s1, b0		# load address of first biomorph
li $s2, 9		# conter for number of biomorphs left to generate
rloop2:
move $a0, $s1		# move address of array to a0 for call
jal getRandomBio	# get a random biomorph for this array
add $s1, $s1, $s0	# increment the array pointer by the length of 1 biomorph array
addi $s2, $s2, -1	# decrement counter
bgtz $s2, rloop2	# if ther biomorph counter is still positive loop
lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $ra, 12($sp)		# restore return address from stack
addi $sp, $sp, 16	# pop 4 words off stack
jr $ra

# getRandomBio expects: $a0 - address to this biomorphs data array
# registers used:
# $s0 - stores the current pointer to the biomorphs data array, gets incremented in a for loop
getRandomBio:
addi $sp, $sp, -12	# make room on stack for 3 words
sw $ra, 8($sp)		# store return address on stack
sw $s2, 4($sp)		# store s2 on stack
sw $s0, 0($sp)		# store s0 on stack 

move $s0, $a0		# copy biomorphs array pointer to s0
lw $s2, numberOfGenes	# counter for numberof genes still left to generate
randGeneLoop:
# this is a for loop looping through the biomorphs data array
jal getRandomGene	# gets a random value between -10 & 10
sw $v0, 0($s0)		# store "new" data value in child array
addi $s2, $s2, -1	# subtract 1 from number of genes left to mutate
addi $s0, $s0, 4	# move to next word in parent array
bgtz $s2, randGeneLoop	# if the number of genes left is greater than zero, loop

addi $s0, $s0, -4	# go back 1 word
lw $t0, 0($s0)		# load last word back from array
abs $t0, $t0		# get the absolute value of the number of nodes
sw $t0, 0($s0)		# store the new number of nodes back in the table

lw $s0, 0($sp)		# restore s0 from stack
lw $s2, 4($sp)		# restore s2 from stack
lw $ra, 8($sp)		# restore return address from stack
addi $sp, $sp, 12	# pop 3 words from stack
jr $ra		# all children have been made, return to caller

newParent:
lw $t0, numberOfGenes	# counter for number of genes needed to copy
la $t1, parent		# load address of parent array
parentGeneLoop:
lw $t2, 0($a0)		# load gene from the child biomorph
sw $t2, 0($t1)		# store the child gene in the parent array
addi $t0, $t0, -1	# decrement gene counter
addi $t1, $t1, 4	# move parent array pointer to next word
addi $a0, $a0, 4	# move child array pointer to next word
bgtz $t0, parentGeneLoop
jr $ra


# breedChildren pulls data from the parent array and copies/mutates genes to produce 9 new children in the children array
# breedChildren expects: N/A
breedChildren:
addi $sp, $sp, -20	# make room on stack for 5 words
sw $ra, 16($sp)		# store return address on stack
sw $s3, 12($sp)		# store s3 on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack 

la $s1, b0		# load address to beginning of children array
li $s3, 9		# conter for number of children left to create

childLoop:
la $s0, parent		# load address to parent array
lw $s2, numberOfGenes	# counter for numberof genes still left to copy/mutate
geneLoop:
# this is an inner for loop, looping throught all genes
li $a0, 20		# load for 20% mutation rate
jal shouldMutate	# determine if this gene should be mutated or not
li $t1, 0		# mutation amount
beqz $v0, skipM		# if v0 == 0 dont mutate
li $a0, 50		# setup for 50% chance
jal shouldMutate
li $t1, -2		# default will be to increase gene, more negative
beqz $v0, skipM		# if the result came back as 0, leave as -2
mul $t1, $t1, -1	# invert mutation value
skipM:
lw $t0, 0($s0)		# load data value from parent array to t2
bgt $t0, 13, atMax	# if the number is greater than 13, mutating would push it over the limit
blt $t0, -13, atMax	# if < -13, subtracting would also push over the limit
add $t0, $t0, $t1	# add mutation amount to parent value
atMax:
sw $t0, 0($s1)		# store "new" data value in child array
addi $s2, $s2, -1	# subtract 1 from number of genes left to mutate
addi $s0, $s0, 4	# move to next word in parent array
addi $s1, $s1, 4	# move to next word in child array
bgtz $s2, geneLoop	# if the number of genes left is greater than zero, loop
addi $s3, $s3, -1	# subtract 1 from counter of children left to make
bgtz $s3, childLoop	# if the number of children still left to make is greater than zero, loop

lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $s3, 12($sp)		# restore s3 from stack
lw $ra, 16($sp)		# restore return address from stack
addi $sp, $sp, 20	# pop 5 words from stack
jr $ra		# all children have been made, return to caller


# invertWidths inverts all the width values so the biomorph so the left and right can be mirrors of each other
# invertWidths expects:
# $a0 - biomorphs base address
# returns: N/A
invertWidths:
lw $t0, tw		# load offset value for triWidth
add $t0, $a0, $t0	# add offset to base address
lw $t1, 0($t0)		# load value of triWidth from table into t1
mul $t1, $t1, -1	# invert triWidth
sw $t1, 0($t0)		# store inverted value back in table

lw $t0, bcw		# load offset value for b->c width
add $t0, $a0, $t0	# add offset to base address
lw $t1, 0($t0)		# load value of b->c width from table into t1
mul $t1, $t1, -1	# invert b_cWidth
sw $t1, 0($t0)		# store inverted value back in table

lw $t0, baw		# load offset value for b->a width
add $t0, $a0, $t0	# add offset to base address
lw $t1, 0($t0)		# load value of b->a width from table into t1
mul $t1, $t1, -1	# invert b_aWidth
sw $t1, 0($t0)		# store inverted value back in table

lw $t0, cbw		# load offset value for c->b width
add $t0, $a0, $t0	# add offset to base address
lw $t1, 0($t0)		# load value of c->b width from table into t1
mul $t1, $t1, -1	# invert c_bWidth
sw $t1, 0($t0)		# store inverted value back in table
jr $ra			# return to caller

# drawOrigin draws the starting A-shape which all biomorphs begin from, this shape does not count as one of the leaves
# drawOrigin expects: 
# $a0 - x starting coordinate
# $a1 - y starting coordinate
# $a2 - address to this biomorphs data array
# registers used:
# $s0 - address to the biomorphs data array
# $s1 - starting x coordinate
# $s2 - starting y coordinate
# $s3 - integer value of triangleWidth
# $s4 - integer value of triangleHeight
# $s5 - original number of leaves stored in the array, before / 2
drawOrigin:
addi $sp, $sp, -28	# make room for 7 words
sw $ra, 24($sp)		# store return address on stack
sw $s5, 20($sp)		# store s5 on stack
sw $s4, 16($sp)		# store s4 on stack
sw $s3, 12($sp)		# store s3 on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack

add $s0, $0, $a2	# copy address to the biomorphs data array to s0
move $s1, $a0		# copy all coordinates to s registers so i have them when i jump back
move $s2, $a1


lw $t1, nodes		# load the offset value for the nodes value in the array
add $t1, $s0, $t1	# add offset value to the base address
lw $t0, 0($t1)		# load value for nodes from table
abs $t0, $t0
srl $t0, $t0, 1		# divide leaves by 2
add $t0, $t0, 3		# add 3 to, so leaves will always be at least 3
sw $t0, 0($t1)		# store new number of leaves back in variable

lw $s3, tw		# load address offset of triWidth (0)
lw $s4, th		# load address offset of triHeight (4)
add $s3, $s0, $s3	# add triangleWidth offset to array address
add $s4, $s0, $s4	# add triangleHeight offset to array address
lw $s3, 0($s3)		# load value of triangle width into s3
lw $s4, 0($s4)		# load value of triangle height into s4
add $a2, $s1, $s3	# add the triWidth offset to the starting x cord
sub $a3, $s2, $s4	# subtract triangle height, from starting y cord
jal DrawLine
move $a0, $a2		# start x point becomes end y point
move $a1, $a3		# start y point becomes end y point
move $a2, $s0		# copy base address to $a2
jal drawC		# we still need more leaves, draw a C figure

move $a0, $s0		# copy biomorph base address to a0 for invert call
jal invertWidths	# invert all width values

lw $s3, 0($s0)		# load triWidth from table to s3, should have negative value now

move $a0, $s1
move $a1, $s2
add $a2, $s1, $s3	# add the triWidth offset to the starting x cord
sub $a3, $s2, $s4	# subtract triangle height, from starting y cord
jal DrawLine
move $a0, $a2		# start x point becomes end y point
move $a1, $a3		# start y point becomes end y point
move $a2, $s0		# copy base address to $a2
jal drawC		# we still need more leaves, draw a C figure

lw $t1, nodes		# load the offset value for the nodes value in the array
add $t1, $s0, $t1	# add offset value to the base address
lw $t0, 0($t1)		# load value for nodes from table
sub $t0, $t0, 3		# subtract the 3 I added earlier
sll $t0, $t0, 1		# multiply by 2
sw $t0, 0($t1)		# store new number of leaves back in variable
move $a0, $s0		# copy biomorph base address to a0 for invert call
jal invertWidths	# invert all width values

lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $s3, 12($sp)		# restore s3 from stack
lw $s4, 16($sp)		# restore s4 from stack
lw $s5, 20($sp)		# restore s5 from stack
lw $ra, 24($sp)		# restore return address from stack
addi $sp, $sp, 28	# pop 7 words from stack
jr $ra		# return back to drawB call

# drawA expects: 
# $a0 - x coord of starting point
# $a1 - y coord of starting point
# $a2 - base address for this biomorphs data array
# draws the A figure
drawA:
addi $sp, $sp, -16	# make room for 4 words
sw $ra, 12($sp)		# store return address on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack
move $s0, $a0	# copy all coordinates to s registers so i have them when i jump back
move $s1, $a1
move $s2, $a2	# move base address of array to s2
jal drawAleft	# jump to drawing A's left leg
move $a0, $s0	# copy value from s0 back to a0 for next call
move $a1, $s1	# copy value from s1 back to a1 for next call
move $a2, $s2	# copy base address of array to a2 for next call
jal drawAright	# jump to drawing A's right leg
lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $ra, 12($sp)		# restore return address from stack
addi $sp, $sp, 16	# pop 4 word from stack
jr $ra	

drawAleft:
addi $sp, $sp, -16	# make room for 4 words
sw $ra, 12($sp)		# store return address on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack
move $s2, $a2		# copy base address to s2

lw $t0, tw		# load offset value for triWidth
add $t0, $a2, $t0	# add offset value to base address
lw $t0, 0($t0)		# load value of triWidth
lw $t1, th		# load offset value for triHeight
add $t1, $a2, $t1	# add triHeight offset to base address
lw $t1, 0($t1)		# load value of triHeight from table
add $a2, $a0, $t0	# add the triWidth offset to the starting x cord
sub $a3, $a1, $t1	# subtract triHeight, from starting y cord
jal DrawLine

lw $t1, nodes		# load the offset value for the nodes value in the array
add $t1, $s2, $t1	# add offset value to the base address
lw $t0, 0($t1)		# load value for nodes from table
subi $t0, $t0, 1	# subtract 1 from leaves needed
sw $t0, 0($t1)		# store new number of leaves back in variable
beqz $t0, alGoBack	# if no more leaves to draw, go back a node
move $a0, $a2	# start x point becomes end y point
move $a1, $a3	# start y point becomes end y point
move $a2, $s2	# copy base address from s2 back to a2 for next call
jal drawC	# we still need more leaves, draw a C figure
alGoBack:
lw $t0, nodes		# load the offset value for the nodes value in the array
add $t0, $s2, $t0	# add offset value to the base address
lw $t1, 0($t0)		# load value for nodes from table
addi $t1, $t1, 1	# add 1 to leaves needed to draw, since were going back
sw $t1, 0($t0)		# store new number of leaves back in variable
lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $ra, 12($sp)		# restore return address from stack
addi $sp, $sp, 16	# pop 4 word from stack
jr $ra		# return back to drawB call

drawAright:
addi $sp, $sp, -16	# make room for 4 words
sw $ra, 12($sp)		# store return address on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack
move $s2, $a2		# copy base address to s2

lw $t0, tw		# load offset value for triWidth
add $t0, $a2, $t0	# add offset value to base address
lw $t0, 0($t0)		# load value of triWidth
mul $t0, $t0, -1	# get opposite of triWidth to draw right half
lw $t1, th		# get offset value for triHeight
add $t1, $a2, $t1	# add triHeight offset to base address
lw $t1, 0($t1)		# load value of triHeight from table
add $a2, $a0, $t0	# add the triWidth offset to the starting x cord
sub $a3, $a1, $t1	# subtract triHeight, from starting y cord
jal DrawLine

lw $t1, nodes		# load the offset value for the nodes value in the array
add $t1, $s2, $t1	# add offset value to the base address
lw $t0, 0($t1)		# load value for nodes from table
subi $t0, $t0, 1	# subtract 1 from leaves needed
sw $t0, 0($t1)		# store new number of leaves back in variable
beqz $t0, arGoBack	# if no more leaves to draw, go back a node
move $a0, $a2	# start x point becomes end y point
move $a1, $a3	# start y point becomes end y point
move $a2, $s2	# copy base address from s2 to a2 for call
jal drawC	# we still need more leaves, draw a C figure
arGoBack:
lw $t0, nodes		# load the offset value for the nodes value in the array
add $t0, $s2, $t0	# add offset value to the base address
lw $t1, 0($t0)		# load value for nodes from table
addi $t1, $t1, 1	# add 1 to leaves needed to draw, since were going back
sw $t1, 0($t0)		# store new number of leaves back in variable
lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $ra, 12($sp)		# restore return address from stack
addi $sp, $sp, 16	# pop 4 word from stack
jr $ra


# drawB expects: 
# $a0 - x coord of starting point
# $a1 - y coord of starting point
# $a2 - base address to the current biomorphs array
# draws the B figure
drawB:
addi $sp, $sp, -16	# make room for 4 words
sw $ra, 12($sp)		# store return address on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack
move $s0, $a0	# copy all coordinates to s registers so i have them when i jump back
move $s1, $a1
move $s2, $a2	# move base address of array to s2
jal drawBleft	# jump to drawing B's left leg
move $a0, $s0	# copy value from s0 back to a0 for next call
move $a1, $s1	# copy value from s1 back to a1 for next call
move $a2, $s2	# copy base address of array to a2 for next call
jal drawBright	# jump to drawing B's right leg
lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $ra, 12($sp)		# restore return address from stack
addi $sp, $sp, 16	# pop 4 word from stack
jr $ra			


drawBleft:
addi $sp, $sp, -16	# make room for 4 words
sw $ra, 12($sp)		# store return address on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack
move $s2, $a2		# copy base address to s2

lw $t0, bcw		# load offset value for b->c width
add $t0, $a2, $t0	# add offset value to base address
lw $t0, 0($t0)		# load value of b->c width
lw $t1, bch		# load offset value for triHeight
add $t1, $a2, $t1	# add triHeight offset to base address
lw $t1, 0($t1)		# load value of triHeight from table
add $a2, $a0, $t0	# add the b->c width to the starting x cord
sub $a3, $a1, $t1	# subtract triHeight, from starting y cord
jal DrawLine

lw $t1, nodes		# load the offset value for the nodes value in the array
add $t1, $s2, $t1	# add offset value to the base address
lw $t0, 0($t1)		# load value for nodes from table
subi $t0, $t0, 1	# subtract 1 from leaves needed
sw $t0, 0($t1)		# store new number of leaves back in variable
beqz $t0, blGoBack	# if no more leaves to draw, go back a node
move $a0, $a2	# start x point becomes end y point
move $a1, $a3	# start y point becomes end y point
move $a2, $s2	# copy base address from s2 to a2
jal drawC	# we still need more leaves, draw a C figure
blGoBack:
lw $t0, nodes		# load the offset value for the nodes value in the array
add $t0, $s2, $t0	# add offset value to the base address
lw $t1, 0($t0)		# load value for nodes from table
addi $t1, $t1, 1	# add 1 to leaves needed to draw, since were going back
sw $t1, 0($t0)		# store new number of leaves back in variable
lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $ra, 12($sp)		# restore return address from stack
addi $sp, $sp, 16	# pop 4 word from stack
jr $ra		# return back to drawB call

drawBright:
addi $sp, $sp, -16	# make room for 4 words
sw $ra, 12($sp)		# store return address on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack

move $s2, $a2		# copy base address to s2
lw $t0, baw		# load offset value for b->a width
add $t0, $a2, $t0	# add offset value to base address
lw $t0, 0($t0)		# load value of b->a width
lw $t1, bah		# load offset value for b->a height
add $t1, $a2, $t1	# add b->a height offset to base address
lw $t1, 0($t1)		# load value of b->a height from table
add $a2, $a0, $t0	# add the b->a width to the starting x cord
sub $a3, $a1, $t1	# subtract b->a height, from starting y cord
jal DrawLine

lw $t1, nodes		# load the offset value for the nodes value in the array
add $t1, $s2, $t1	# add offset value to the base address
lw $t0, 0($t1)		# load value for nodes from table
subi $t0, $t0, 1	# subtract 1 from leaves needed
sw $t0, 0($t1)		# store new number of leaves back in variable
beqz $t0, brGoBack	# if no more leaves to draw, go back a node
move $a0, $a2	# start x point becomes end y point
move $a1, $a3	# start y point becomes end y point
move $a2, $s2	# copy base address from s2 to a2
jal drawA	# we still need more leaves, draw a C figure
brGoBack:
lw $t0, nodes		# load the offset value for the nodes value in the array
add $t0, $s2, $t0	# add offset value to the base address
lw $t1, 0($t0)		# load value for nodes from table
addi $t1, $t1, 1	# add 1 to leaves needed to draw, since were going back
sw $t1, 0($t0)		# store new number of leaves back in variable
lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $ra, 12($sp)		# restore return address from stack
addi $sp, $sp, 16	# pop 4 word from stack
jr $ra

# drawC expects: 
# $a0 - x coord of starting point
# $a1 - y coord of starting point
# $a2 - address to start of biomorphs array
drawC:
addi $sp, $sp, -16	# make room for 4 words
sw $ra, 12($sp)		# store return address on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack
move $s0, $a0	# copy all coordinates to s registers so i have them when i jump back
move $s1, $a1
move $s2, $a2	# move base address of array to s2
jal drawCleft	# jump to drawing C's left leg
move $a0, $s0	# copy value from s0 back to a0 for next call
move $a1, $s1	# copy value from s1 back to a1 for next call
move $a2, $s2	# copy base address of array to a2 for next call
jal drawCright	# jump to drawing C's right leg
lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $ra, 12($sp)		# restore return address from stack
addi $sp, $sp, 16	# pop 4 word from stack
jr $ra		


# drawCleft expects:
# $a0 - the starting x coordinate
# $a1 - the starting y coordinate
# $a2 - the base address for this biomorphs data array
drawCleft:
addi $sp, $sp, -16	# make room for 4 words
sw $ra, 12($sp)		# store return address on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack
move $s2, $a2		# copy base address to s2

lw $t0, cbw		# load offset value for c->b width
add $t0, $a2, $t0	# add offset value to base address
lw $t0, 0($t0)		# load value of c->b width
lw $t1, cbh		# load offset value for c->b height
add $t1, $a2, $t1	# add c->b height offset to base address
lw $t1, 0($t1)		# load value of c->b height from table
add $a2, $a0, $t0	# add the b->c width to the starting x cord
sub $a3, $a1, $t1	# subtract c->b height, from starting y cord
jal DrawLine

lw $t1, nodes		# load the offset value for the nodes value in the array
add $t1, $s2, $t1	# add offset value to the base address
lw $t0, 0($t1)		# load value for nodes from table
subi $t0, $t0, 1	# subtract 1 from leaves needed
sw $t0, 0($t1)		# store new number of leaves back in variable
beqz $t0, clGoBack	# if no more leaves to draw, go back a node
move $a0, $a2	# start x point becomes end y point
move $a1, $a3	# start y point becomes end y point
move $a2, $s2	# copy base address from s2 to a2 for call
jal drawB	# we still need more leaves, draw a B figure
clGoBack:
lw $t0, nodes		# load the offset value for the nodes value in the array
add $t0, $s2, $t0	# add offset value to the base address
lw $t1, 0($t0)		# load value for nodes from table
addi $t1, $t1, 1	# add 1 to leaves needed to draw, since were going back
sw $t1, 0($t0)		# store new number of leaves back in variable
lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $ra, 12($sp)		# restore return address from stack
addi $sp, $sp, 16	# pop 4 word from stack
jr $ra		# return back to drawB call


# drawCright expects:
# $a0 - the starting x coordinate
# $a1 - the starting y coordinate
# $a2 - the base address for this biomorphs data array
drawCright:
addi $sp, $sp, -16	# make room for 4 words
sw $ra, 12($sp)		# store return address on stack
sw $s2, 8($sp)		# store s2 on stack
sw $s1, 4($sp)		# store s1 on stack
sw $s0, 0($sp)		# store s0 on stack
move $s2, $a2		# copy base address to s2

lw $t1, cah		# load offset value for c->a height
add $t1, $a2, $t1	# add offset value to base address
lw $t1, 0($t1)		# load value of c->a height
add $a2, $a0, $0	# copy starting x cord to end x cord
sub $a3, $a1, $t1	# subtract triangle height, to get delta y
jal DrawLine

lw $t1, nodes		# load the offset value for the nodes value in the array
add $t1, $s2, $t1	# add offset value to the base address
lw $t0, 0($t1)		# load value for nodes from table
subi $t0, $t0, 1	# subtract 1 from leaves needed
sw $t0, 0($t1)		# store new number of leaves back in variable
beqz $t0, crGoBack	# if no more leaves to draw, go back a node
move $a0, $a2	# start x point becomes end y point
move $a1, $a3	# start y point becomes end y point
move $a2, $s2	# copy base address from s2 to a2 for call
jal drawA	# we still need more leaves, draw an A figure
crGoBack:
lw $t0, nodes		# load the offset value for the nodes value in the array
add $t0, $s2, $t0	# add offset value to the base address
lw $t1, 0($t0)		# load value for nodes from table
addi $t1, $t1, 1	# add 1 to leaves needed to draw, since were going back
sw $t1, 0($t0)		# store new number of leaves back in variable
lw $s0, 0($sp)		# restore s0 from stack
lw $s1, 4($sp)		# restore s1 from stack
lw $s2, 8($sp)		# restore s2 from stack
lw $ra, 12($sp)		# restore return address from stack
addi $sp, $sp, 16	# pop 4 word from stack
jr $ra


# drawGrid expects: N/A
# draws lines to break up the screen into a 3x3 grid
drawGrid:
addi $sp, $sp, -4	# make room on stack for 1 word
sw $ra, 0($sp)		# store return address on stack
li $a0, 170
li $a1, 0
li $a2, 170
li $a3, 512
jal DrawLine
li $a0, 340
li $a1, 0
li $a2, 340
li $a3, 512
jal DrawLine
li $a0, 0
li $a1, 170
li $a2, 512
li $a3, 170
jal DrawLine
li $a0, 0
li $a1, 340
li $a2, 512
li $a3, 340
jal DrawLine
lw $ra, 0($sp)		# restore return address from stack
addi $sp, $sp, 4	# pop 1 word from stack
jr $ra


end:
	li $v0, 10	# setup to exit
	syscall
	




# $a0 = x
# $a1 = y
DrawPixel:
        la      $t9, 0x10040000 # get the memory start address
        sll     $t0, $a0, 2     # assumes mars was configured as 256 x 256
        addu    $t9, $t9, $t0   # and 1 pixel width, 1 pixel height
        sll     $t0, $a1, 11    # (a0 * 4) + (a1 * 4 * 256)
        addu    $t9, $t9, $t0   # t9 = memory address for this pixel
        li      $t0, 0xffffff   # assumes we draw "white"
        sw      $t0, 0($t9)     # write the color to the memory location
        jr      $ra



#
# Start of the line drawing code
#
checkPoint:
bgez $a0, gtZero	# if a0 is greater than zero jumpto gtZero
add $a0, $0, $0		# if a0 < 0, set a0 to zero, the minimum value
gtZero:
blt $a0, 512, ltMax	# if a0 < 512
add $a0, $0, 511	# set a0 to 511, the maximum value
ltMax:
jr $ra


# DrawLine: Draw a line between two sets of x,y coordinates
# Input:
#  $a0 = starting x coordinate
#  $a1 = starting y coordinate
#  $a2 = ending x coordinate
#  $a3 = ending y coordinate
DrawLine:
        addiu   $sp, $sp, -40
        sw      $s0, 0($sp)             # save s0-s7
        sw      $s1, 4($sp)
        sw      $s2, 8($sp)
        sw      $s3, 12($sp)
        sw      $s4, 16($sp)
        sw      $s5, 20($sp)
        sw      $s6, 24($sp)
        sw      $s7, 28($sp)
        sw      $ra, 32($sp)
        
        jal checkPoint		# a0 is ready for checkPoint
        addi $sp, $sp, -4	# make room for 1 more word
        sw $a0, 0($sp)		# store a0 on stack while i check the rest of the points
        move $a0, $a1
        jal checkPoint
        move $a1, $a0		# move the result back to a1
        move $a0, $a2
        jal checkPoint
        move $a2, $a0		# move result back to a2
        move $a0, $a3
        jal checkPoint
        move $a3, $a0		# move result back to a3
        lw $a0, 0($sp)		# restore a0 from stack
        addi $sp, $sp, 4	# pop the last word off stack

        move    $s0, $a0                # copy a0-a3 to s0-s3
        move    $s1, $a1
        move    $s2, $a2
        move    $s3, $a3

        subu    $s6, $s2, $s0           # delta-x
        lui     $t0, 0x8000
        and     $t0, $t0, $s6           # check for negative
        beq     $t0, $zero, _next1
        subu    $s6, $zero, $s6
_next1:
        subu    $s7, $s3, $s1           # delta-y
        lui     $t0, 0x8000
        and     $t0, $t0, $s7           # check for negative
        beq     $t0, $zero, _next2
        subu    $s7, $zero, $s7
_next2:
        bgeu    $s6, $s7, _next4        # which is greater delta x or y?
# y has the greater delta
        bgeu    $s3, $s1, _next3
        move    $s4, $s0                # swap starting/ending
        move    $s0, $s2
        move    $s2, $s4

        move    $s4, $s1
        move    $s1, $s3
        move    $s3, $s4
_next3:
        subu    $s6, $s2, $s0           # delta-x
        subu    $s7, $s3, $s1           # delta-y

        li      $s4, 1
        sw      $s4, 36($sp)
        lui     $t0, 0x8000
        and     $t0, $t0, $s6           # check for negative
        beq     $t0, $zero, _line2
        li      $s4, -1
        sw      $s4, 36($sp)
        subu    $s6, $zero, $s6
        j       _line2
# x has the greater delta
_next4:
        bgeu    $s2, $s0, _line1
        move    $s4, $s0                # swap starting/ending
        move    $s0, $s2
        move    $s2, $s4

        move    $s4, $s1
        move    $s1, $s3
        move    $s3, $s4
_line1:
        subu    $s6, $s2, $s0           # delta-x
        subu    $s7, $s3, $s1           # delta-y

        li      $s4, 1
        sw      $s4, 36($sp)
        lui     $t0, 0x8000
        and     $t0, $t0, $s7           # check for negative
        beq     $t0, $zero, _line2
        li      $s4, -1
        sw      $s4, 36($sp)
        subu    $s7, $zero, $s7
_line2:

        bltu    $s6, $s7, _line5
        sll     $s4, $s7, 1
        subu    $s4, $s4, $s6

        move    $s5, $s6
_line3:
        beq     $s5, $zero, _line8
        move    $a0, $s0
        move    $a1, $s1
        jal     DrawPixel
        addiu   $s0, $s0, 1
        addu    $s4, $s4, $s7
        addu    $s4, $s4, $s7
        lui     $t0, 0x8000
        and     $t0, $t0, $s4
        bne     $t0, $zero, _line4
        lw      $t0, 36($sp)
        addu    $s1, $s1, $t0
        subu    $s4, $s4, $s6
        subu    $s4, $s4, $s6
_line4:
        addiu   $s5, $s5, -1
        j       _line3

_line5:
        sll     $s4, $s6, 1
        subu    $s4, $s4, $s7

        move    $s5, $s7
_line6:
        beq     $s5, $zero, _line8
        move    $a0, $s0
        move    $a1, $s1
        jal     DrawPixel
        addiu   $s1, $s1, 1
        addu    $s4, $s4, $s6
        addu    $s4, $s4, $s6
        lui     $t0, 0x8000
        and     $t0, $t0, $s4
        bne     $t0, $zero, _line7
        lw      $t0, 36($sp)
        addu    $s0, $s0, $t0
        subu    $s4, $s4, $s7
        subu    $s4, $s4, $s7
_line7:
        addiu   $s5, $s5, -1
        j       _line6
_line8:
        move    $a0, $s2
        move    $a1, $s3
        jal     DrawPixel

        lw      $s0, 0($sp)
        lw      $s1, 4($sp)
        lw      $s2, 8($sp)
        lw      $s3, 12($sp)
        lw      $s4, 16($sp)
        lw      $s5, 20($sp)
        lw      $s6, 24($sp)
        lw      $s7, 28($sp)
        lw      $ra, 32($sp)
        addiu   $sp, $sp, 40
        jr      $ra
