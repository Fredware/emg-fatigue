function idx=SE(Features)
[EMGMatrix,EMGChanPairs,BadEMGIdxs] = genEMGMatrix([0]);
idx=find(sum(EMGMatrix));
% idx=[1,2,3,4,11,12,13,14,21,22,23,24,31,32,33,34,41,42,43,44,51,52,53,54,61,62,63,64,71,72,73,74];
end 