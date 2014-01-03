# easyalign.py
# copyright (c) Jason M. Kinser 2008
# This code is intended for non-commercial, educational use.
# This code may not be used for commercial purposes without written permission from the author.
# Many routines in this file are found in:
#  "Python for Bioinformatics", J. Kinser,  Jones & Bartlett pub, 2008


from numpy import *
# Code 7-1
# scoring an alignment.  +1 for a match. -1 for mismatch
# -2 for gaps
def SimpleScore( s1, s2 ):
    a1 = map( ord, list(s1) )
    a2 = map( ord, list(s2) )
    # count matches
    a1 = list(a1)
    a2 = list(a2)
    print(equal(a1,a2))
    score = ( equal( a1, a2 )).astype(int).sum()
    print(score)
    # count mismatches
    score = score - ( not_equal( a1,a2) ).astype(int).sum()
    # gaps
    ngaps = s1.count( '-' ) + s2.count('-')
    score = score - ngaps
    return score

# Code 7-5
# scoring an alignment using the blosum matrix or equivalent
def BlosumScore( mat, abet, s1, s2, gap=-8 ):
    sc = 0
    n = min( [len(s1), len(s2)] )
    for i in range( n ):
        if s1[i] == '-' or s2[i] == '-' and s1[i] != s2[i]:
            sc += gap
        elif s1[i] == '.' or s2[i] == '.':
            pass
        else:
            n1 = abet.index( s1[i] )
            n2 = abet.index( s2[i] )
            sc += mat[n1,n2]
    return sc

# Code 7-6
# align two sequences using a brute force slide and the blosum matrix
def BruteForceSlide( mat, abet, seq1, seq2 ):
    # length of strings
    l1, l2  = len( seq1 ), len( seq2 )  #####
    # make new string with leader
    t1 = len(seq2) * '.' + seq1
    print(t1)
    lt = len( t1 )
    answ = zeros( lt, int )
    for i in range( lt ):
        print(i, t1[i:], seq2,sep=' # ')
        answ[i] = BlosumScore( mat, abet, t1[i:], seq2 )
    return answ

def PBET50():
    return 'ABCDEFGHIKLMNPQRSTVWXYZ'

# Code 8-1
# Create a scoring matrix and arrow matrix
# mat: input substitution matrix
# abet: alphabet
# seq1, seq2: strings to be aligned
# gap: gap penalty
# returns: scoring matrix, arrow matrix
def ScoringMatrix( mat, abet, seq1, seq2, gap=-8 ):
    l1, l2 = len( seq1), len(seq2)
    scormat = zeros( (l1+1,l2+1), int )
    arrow = zeros( (l1+1,l2+1), int )
    # create first row and first column
    print(arange(l2+1))
    scormat[0,:] = arange(l2+1)* gap
    scormat[:,0] = arange( l1+1)* gap
    print(scormat)
    print(arrow)
    arrow[0] = ones(l2+1)
    print(arrow)
    for i in range( 1, l1+1 ):
        for j in range( 1, l2+1 ):
            f = zeros( 3 )
            f[0] = scormat[i-1,j] + gap
            f[1] = scormat[i,j-1] + gap
            n1 = abet.index( seq1[i-1] )
            n2 = abet.index( seq2[j-1] )
            f[2] = scormat[i-1,j-1] + mat[n1,n2]
            #if i==1 and j==1: print f
            scormat[i,j] = f.max()
            arrow[i,j] = f.argmax()
    return scormat, arrow

# Code 8-3
# backtrace to create alignments
# arrow: arrow matrix
# seq1, seq2: strings to be aligned
# returns aligned strings
def Backtrace( arrow, seq1, seq2 ):
    st1, st2 = '',''
    v,h = arrow.shape
    ok = 1
    v-=1
    h-=1
    while ok:
        if arrow[v,h] == 0:
            st1 += seq1[v-1]
            st2 += '-'
            v -= 1
        elif arrow[v,h] == 1:
            st1 += '-'
            st2 += seq2[h-1]
            h -= 1
        elif arrow[v,h] == 2:
            st1 += seq1[v-1]
            st2 += seq2[h-1]
            v -= 1
            h -= 1
        if v==0 and h==0:
            ok = 0
    # reverse the strings
    st1 = st1[::-1]
    st2 = st2[::-1]
    return st1, st2





B50 = array( [ [ 5,-2,-1,-2,-1,-3, 0,-2,-1,-1,-2,-1,-1,-1,-1,-2, 1, 0, 0,-3,-1,-2,-1],
  [-2, 5,-3, 5, 1,-4,-1, 0,-4, 0,-4,-3, 4,-2, 0,-1, 0, 0,-4,-5,-1,-3, 2],
  [-1,-3,13,-4,-3,-2,-3,-3,-2,-3,-2,-2,-2,-4,-3,-4,-1,-1,-1,-5,-2,-3,-3],
  [-2, 5,-4, 8, 2,-5,-1,-1,-4,-1,-4,-4, 2,-1, 0,-2, 0,-1,-4,-5,-1,-3, 1],
  [-1, 1,-3, 2, 6,-3,-3, 0,-4, 1,-3,-2, 0,-1, 2, 0,-1,-1,-3,-3,-1,-2, 5],
  [-3,-4,-2,-5,-3, 8,-4,-1, 0,-4, 1, 0,-4,-4,-4,-3,-3,-2,-1, 1,-2, 4,-4],
  [ 0,-1,-3,-1,-3,-4, 8,-2,-4,-2,-4,-3, 0,-2,-2,-3, 0,-2,-4,-3,-2,-3,-2],
  [-2, 0,-3,-1, 0,-1,-2,10,-4, 0,-3,-1, 1,-2, 1, 0,-1,-2,-4,-3,-1, 2, 0],
  [-1,-4,-2,-4,-4, 0,-4,-4, 5,-3, 2, 2,-3,-3,-3,-4,-3,-1, 4,-3,-1,-1,-3],
  [-1, 0,-3,-1, 1,-4,-2, 0,-3, 6,-3,-2, 0,-1, 2, 3, 0,-1,-3,-3,-1,-2, 1],
  [-2,-4,-2,-4,-3, 1,-4,-3, 2,-3, 5, 3,-4,-4,-2,-3,-3,-1, 1,-2,-1,-1,-3],
  [-1,-3,-2,-4,-2, 0,-3,-1, 2,-2, 3, 7,-2,-3, 0,-2,-2,-1, 1,-1,-1, 0,-1],
  [-1, 4,-2, 2, 0,-4, 0, 1,-3, 0,-4,-2, 7,-2, 0,-1, 1, 0,-3,-4,-1,-2, 0],
  [-1,-2,-4,-1,-1,-4,-2,-2,-3,-1,-4,-3,-2,10,-1,-3,-1,-1,-3,-4,-2,-3,-1],
  [-1, 0,-3, 0, 2,-4,-2, 1,-3, 2,-2, 0, 0,-1, 7, 1, 0,-1,-3,-1,-1,-1, 4],
  [-2,-1,-4,-2, 0,-3,-3, 0,-4, 3,-3,-2,-1,-3, 1, 7,-1,-1,-3,-3,-1,-1, 0],
  [ 1, 0,-1, 0,-1,-3, 0,-1,-3, 0,-3,-2, 1,-1, 0,-1, 5, 2,-2,-4,-1,-2, 0],
  [ 0, 0,-1,-1,-1,-2,-2,-2,-1,-1,-1,-1, 0,-1,-1,-1, 2, 5, 0,-3, 0,-2,-1],
  [ 0,-4,-1,-4,-3,-1,-4,-4, 4,-3, 1, 1,-3,-3,-3,-3,-2, 0, 5,-3,-1,-1,-3],
  [-3,-5,-5,-5,-3, 1,-3,-3,-3,-3,-2,-1,-4,-4,-1,-3,-4,-3,-3,15,-3, 2,-2],
  [-1,-1,-2,-1,-1,-2,-2,-1,-1,-1,-1,-1,-1,-2,-1,-1,-1, 0,-1,-3,-1,-1,-1],
  [-2,-3,-3,-3,-2, 4,-3, 2,-1,-2,-1, 0,-2,-3,-1,-1,-2,-2,-1, 2,-1, 8,-2],
  [-1, 2,-3, 1, 5,-4,-2, 0,-3, 1,-3,-1, 0,-1, 4, 0, 0,-1,-3,-2,-1,-2, 5] ] )

#PBET_kinser = 'ARNDCQEGHILKMFPSTWYV'
#PBET62 = 'ACDEFGHIKLMNPQRSTVWY'

blosum62_similarity_scores = [
  [  4,  0, -2, -1, -2,  0, -2, -1, -1, -1, -1, -2, -1, -1, -1,  1,  0,  0, -3, -2 ],
  [  0,  9, -3, -4, -2, -3, -3, -1, -3, -1, -1, -3, -3, -3, -3, -1, -1, -1, -2, -2 ],
  [ -2, -3,  6,  2, -3, -1, -1, -3, -1, -4, -3,  1, -1,  0, -2,  0, -1, -3, -4, -3 ],
  [ -1, -4,  2,  5, -3, -2,  0, -3,  1, -3, -2,  0, -1,  2,  0,  0, -1, -2, -3, -2 ],
  [ -2, -2, -3, -3,  6, -3, -1,  0, -3,  0,  0, -3, -4, -3, -3, -2, -2, -1,  1,  3 ],
  [  0, -3, -1, -2, -3,  6, -2, -4, -2, -4, -3,  0, -2, -2, -2,  0, -2, -3, -2, -3 ],
  [ -2, -3, -1,  0, -1, -2,  8, -3, -1, -3, -2,  1, -2,  0,  0, -1, -2, -3, -2,  2 ],
  [ -1, -1, -3, -3,  0, -4, -3,  4, -3,  2,  1, -3, -3, -3, -3, -2, -1,  3, -3, -1 ],
  [ -1, -3, -1,  1, -3, -2, -1, -3,  5, -2, -1,  0, -1,  1,  2,  0, -1, -2, -3, -2 ],
  [ -1, -1, -4, -3,  0, -4, -3,  2, -2,  4,  2, -3, -3, -2, -2, -2, -1,  1, -2, -1 ],
  [ -1, -1, -3, -2,  0, -3, -2,  1, -1,  2,  5, -2, -2,  0, -1, -1, -1,  1, -1, -1 ],
  [ -2, -3,  1,  0, -3,  0,  1, -3,  0, -3, -2,  6, -2,  0,  0,  1,  0, -3, -4, -2 ],
  [ -1, -3, -1, -1, -4, -2, -2, -3, -1, -3, -2, -2,  7, -1, -2, -1, -1, -2, -4, -3 ],
  [ -1, -3,  0,  2, -3, -2,  0, -3,  1, -2,  0,  0, -1,  5,  1,  0, -1, -2, -2, -1 ],
  [ -1, -3, -2,  0, -3, -2,  0, -3,  2, -2, -1,  0, -2,  1,  5, -1, -1, -3, -3, -2 ],
  [  1, -1,  0,  0, -2,  0, -1, -2,  0, -2, -1,  1, -1,  0, -1,  4,  1, -2, -3, -2 ],
  [  0, -1, -1, -1, -2, -2, -2, -1, -1, -1, -1,  0, -1, -1, -1,  1,  5,  0, -2, -2 ],
  [  0, -1, -3, -2, -1, -3, -3,  3, -2,  1,  1, -3, -2, -2, -3, -2,  0,  4, -3, -1 ],
  [ -3, -2, -4, -3,  1, -2, -2, -3, -3, -2, -1, -4, -4, -2, -3, -3, -2, -3, 11,  2 ],
  [ -2, -2, -3, -2,  3, -3,  2, -1, -2, -1, -1, -2, -3, -1, -2, -2, -2, -1,  2,  7 ],
  ]

gap_penalty = -8

PBET = PBET50();
print(SimpleScore('A-TCGATCGATT','AGTCGATCGATT'))
a = 'RNDKPKFSTARN'
b = 'RNQKPKWWTATN'
score = BlosumScore(B50,PBET,a,b)
print('score: '+str(score))

mat,arrow =ScoringMatrix(B50,PBET,'RNDKPKFSTARN','PKFSTA')
print(mat)
print(arrow)
for i in Backtrace(arrow,'RNDKPKFSTARN','PKFSTA'):
    print(i)
