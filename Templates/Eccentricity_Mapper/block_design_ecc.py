#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Sep 26 12:32:05 2021

@author: kurtb
"""
import sys
sys.path.insert(0, '/Users/duffieldsj/documents/GitHub/nilearn')
from nilearn.glm.first_level import make_first_level_design_matrix
from nilearn.plotting import plot_design_matrix
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from pprint import pprint
from nilearn.glm.first_level import FirstLevelModel
from statsmodels.stats.outliers_influence import variance_inflation_factor
from nilearn.glm.first_level import run_glm
import os
from nilearn.glm.contrasts import compute_contrast
import scipy as sp
from scipy import stats
import warnings
warnings.simplefilter(action='ignore', category=FutureWarning)

#%%

nreps=None# if not none, force nreps
hrf = ['mion','spm'][0]
githubF = '/Users/duffieldsj/documents/GitHub'
simF = githubF+'/fMRI-Stimuli/Templates/Eccentricity_Mapper'

nSims = 10000
blockLenMinMax = [5*60,9*60 ] # not including blank period


blockSec = 30
stimDur =  blockSec # efficiency best when stimDur = blocksec
TR = 3

blankSecs = blockSec # at end of run




# CONDITIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
conditions = np.random.permutation(['1','3','7','26'])

sim_name = 'nConds%d_weights01_blockSec%d_stimDur%d'%(len(conditions),
                                                      blockSec,
                                                      stimDur)

print('\n'+'-'*30)
print('design info:\n')
print('nConditions = %d'%len(conditions))
if np.mod(len(conditions),2)!=0:
    print('WARNING: len(conditions) is not even (2 x nSequences required)')

#%% functions
def scr(p):
    im = plt.imread(p)
    mask = np.all(im==255/2,axis=2)
    M = im.shape[0]//10
    N = im.shape[1]//10
    tiles = [im[x:x+M,y:y+N] for x in range(0,im.shape[0],M) for y in range(0,im.shape[1],N)]
    
    im2 = np.zeros_like(im)
    stiles = np.random.permutation(tiles)
    # for tile in np.random.permutation(tiles):
    i=0
    for x in range(0,im.shape[0],M):
        for y in range(0,im.shape[1],N):
            im2[x:x+M,y:y+N] = stiles[i]
            i+=1
    return im2


def balanced_latin_squares(n):
    l = [[((j//2+1 if j%2 else n-j//2) + i) % n + 1 for j in range(n)] for i in range(n)]
    if n % 2:  # Repeat reversed for odd n
        l += [seq[::-1] for seq in l]
    return np.array(l)

def get_vif(dm,cs):
    m = np.array(dm)
    didx = {c:np.where([c in col for col in dm.columns])[0][0] for c in cs}
    return {d: variance_inflation_factor(m,i).round(3) for d,i in zip(didx.keys(),didx.values())}


def getIndex(lConditions,c):
    return np.where([c in cond for cond in lConditions])[0]


def simulate_noise(nPath, nPeriod, beta, c, sigma):
    noise = c + sp.random.normal(0, sigma, (nPath, nPeriod))
    sims = np.zeros((nPath, nPeriod))
    sims[:,0] = noise[:,0]
    for period in range(1, nPeriod):
        sims[:,period] = beta*sims[:,period-1] + noise[:,period]
    return sims

def combine_hrf_ar1(vHrf,beta=.01,c=0,sigma = .0035,plot=False):
    '''c=# interecept'''
    v = simulate_noise(1,len(vHrf),beta,c,sigma)
    if plot:
        plt.plot(vHrf)
        plt.plot(v.flatten()+vHrf)
        plt.legend(['hrf','hrf+noise'])
        plt.suptitle(stats.pearsonr(v.flatten()+vHrf,vHrf)[0].round(3))
    return v.flatten()+vHrf

#%% calculate nrep per run

mSeq = balanced_latin_squares(len(conditions))

nRuns = len(mSeq)
print('nRuns = %d'%nRuns)
seqSecs = mSeq.shape[1]*blockSec
seqMin = np.floor(seqSecs/60)
seqModSecs = np.mod(seqSecs,60)
# seqHz = len(conditions)/seqSecs
print('single sequence len = %.2f (s)'%seqSecs)
if not (seqSecs<100):
    print('!!! WARNING: len single sequence >= 100s !!!')
print('single sequence len = %d:%.2d (m:s)'%(seqMin,seqModSecs))
# print('design HZ (should be > .01 and < .1) = %.3f'%seqHz)
if nreps == None:
    print('-- calculating max nreps for desired run time')
    for nreps in range(1,20)[::-1]:
        runSecs = seqSecs*nreps
        if (runSecs>blockLenMinMax[0]):
            if (runSecs<blockLenMinMax[1]):
                break
    if np.mod(nreps,2)!=0:
        print('-- correctiing for odd number of reps per run')
        nreps -= 1
        runSecs = seqSecs*nreps
    print('nStim (and sequence) reps per run = %d'%nreps)
else:
    print('pre-specified nStimulus (and sequence) reps per run= %d'%nreps)
    runSecs = seqSecs*nreps
if np.mod(nreps,2)!=0:
    print('-- WARNING: nreps is odd (how to counterbalance color and greyscale? wihtin run?)')
runSecs+=blankSecs 
# if not np.mod(runSecs,TR) == 0:
#     nTrs = np.ceil(runSecs/TR)
#     runSecs = TR*nTrs
assert(np.mod(runSecs,TR)==0)
    

mSeq2 = np.hstack([mSeq]*nreps)

runMin = np.floor(runSecs/60)
runModSecs = np.mod(runSecs,60)
print('run len = %d:%.2d (m:s)'%(runMin,runModSecs))

sessSec = runSecs*nRuns
sessMin = np.floor(sessSec/60)
sessModSecs = np.mod(sessSec,60)
print('session len (not counting b/w run time) = %d:%.2d (m:s)'%(sessMin,sessModSecs))
    
# print('-'*30+'\n')
#%% timing
frame_times = np.arange(0, runSecs+TR,step=TR)
onsets = np.arange(0,runSecs-blankSecs,blockSec)
assert(len(onsets)==mSeq2.shape[1])
assert(frame_times[-1] - onsets[-1] == blockSec+blankSecs)


duration = [stimDur] *mSeq2.shape[1]
nSeq = 3
seqConditions = [conditions[i-1] for i in mSeq2[nSeq,:]]

# modulation = np.ones(len(seqConditions))
# idx = np.where(['gre' in w for w in seqConditions])[0]
# idx = np.concatenate([idx,
#                      np.where(['pla' in w for w in seqConditions])[0]])
# modulation[idx] -= .5
# modulation = np.array([i/np.sum(modulation) for i in modulation])





# remove grey from design
if 'grey' in conditions:
    idxGrey = getIndex(seqConditions,'grey') # we don't include grey in the design
    seqConditions = [c for c in seqConditions if not 'grey' in c]
    onsets = [onsets[i] for i in np.arange(len(onsets)) if not i in idxGrey]
    duration = [duration[i] for i in np.arange(len(duration)) if not i in idxGrey]
    # modulation_cut = [modulation[i] for i in np.arange(len(modulation)) if not i in idxGrey]

events = pd.DataFrame({'trial_type': seqConditions, 
                       'onset': onsets,
                       'duration': duration,
                       # 'modulation':modulation_cut}, #skio modulation, and do as weighted mean
                       },
                      )

#%% simulate voxels for each hypothesized sensitivity:
    
plt.close('all')
dm = make_first_level_design_matrix(frame_times, 
                                    events,
                                    hrf_model=hrf,
                                    drift_model=None, #include in firstlev model
                                    drift_order=3)
plot_design_matrix(dm)


print('\n'+'-'*30)
print('VIF:\n')
pprint(get_vif(dm,[c for c in dm.columns if not 'const' in c]))
print('\n'+'-'*30+'\n')
#%%
# plt.figure()
# vHrf = np.sum(dm.iloc[:,:8],axis=1)
# plt.plot(vHrf)
