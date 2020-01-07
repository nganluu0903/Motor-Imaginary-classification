    close;clc;clear;
addpath data2a\
addpath data2a\true_labels\
file='A0%dT.gdf';
features=[];labels=[];
featuresE=[];labelsE=[];
fileE='A0%dE.gdf';
truelabelFormat='A0%dE.mat';
for k = 1:9
    %Load train data
    filename=sprintf(file,k);
    [s,HDR]=sload(filename);
    %Load evaluate data
    filenameE=sprintf(fileE,k);
    [sE,HDRE]=sload(filenameE);
    filenameTruelabel=sprintf(truelabelFormat,k);
    trueClass=load(filenameTruelabel);
    %Add true label for evaluate data for kappa score calc
    HDRE.Classlabel=trueClass.classlabel;
    %Feature extraction
    [s,f3, HDR, features, labels, MODE]=process_feature(s,HDR);
    [sE,f3E, HDRE, featuresE, labelsE, MODEE]=process_feature(sE,HDRE);
    % Feature selection: Mutual information (a feature scoring method)
      [F_MI,W_MI] = MI(features,labels,3);
      %Choose 1st-15th feat based on descending weight
      features=features(:,F_MI(1:30)); 
      featuresE=featuresE(:,F_MI(1:30));
%Classification ==================== %  
      rng('default') % For reproducibility
%       lda = fitcdiscr(features,labels,...
%       'OptimizeHyperparameters','auto',...
%       'HyperparameterOptimizationOptions',struct('Holdout',0.3,...
%       'AcquisitionFunctionName','expected-improvement-plus'));
      
      lda = fitcdiscr(features, labels);
    %Compute loss of model and loss of cross-validate model
    %To make sure model is not overfitting
      ResubErr(1,k) = resubLoss(lda);
      cp = cvpartition(labels,'KFold',10);
      cvmodel = crossval(lda,'CVPartition',cp);
      CVErr(1,k) = kfoldLoss(cvmodel);
    %Compute kappa score
    %Train data
      pred_c = predict(lda,features);
      kappa = get_kappa(pred_c, labels,4);
      train_kappa(1,k)=kappa;
    
      
   %Evaluate data
      pred_cE = predict(lda,featuresE);
      kappaE = get_kappa(pred_cE, labelsE,4);
      evaluate_kappa(1,k)=kappaE;
     
end
mean(train_kappa)
mean(evaluate_kappa)

