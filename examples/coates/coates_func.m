function cv_acc = coates_func(X, Y, ...
                              NumCentroids, ...
                              PatchWidth, ...
                              PatchHeight, ...
                              WhiteParam, ...
                              ExtraNoise, ...
                              SVMC, ...
                              KMeansIters)
  fprintf('Experiment:\n');
  fprintf('\tNumCentroids: %d\n', NumCentroids);
  fprintf('\tPatches: %d x %d\n', PatchWidth, PatchHeight);
  fprintf('\tWhiteParam: %f\n', WhiteParam);
  fprintf('\tExtraNoise: %f\n', ExtraNoise);
  fprintf('\tSVM C: %f\n', SVMC);
  fprintf('\tKMeansIters: %d\n', KMeansIters);

  addpath('minFunc');
  
  num_folds   = 5;
  num_patches = 1000; %500000;
  
  % Perform cross-validation.
  fold_accs = zeros([num_folds 1]);
  for fold=1:num_folds
    fprintf('Evaluating fold %d/%d\n', fold, num_folds);
  
    train = (mod([1:size(X,1)], num_folds)+1) ~= fold;
    valid = (mod([1:size(X,1)], num_folds)+1) == fold;
    
    fold_accs(fold) = eval_kmeans(X(train,:), Y(train), ...
                                  X(valid,:), Y(valid));
  end
  
  cv_acc = mean(fold_accs);
  
  function acc=eval_kmeans(trainX, trainY, testX, testY)
    
    CIFAR_DIM=[32 32 3];
    
    % extract random patches
    patches = zeros(num_patches, PatchWidth*PatchHeight*3);
    for i=1:num_patches
      if (mod(i,10000) == 0) fprintf('Extracting patch: %d / %d\n', i, num_patches); end
      
      r = random('unid', CIFAR_DIM(1) - PatchHeight + 1);
      c = random('unid', CIFAR_DIM(2) - PatchWidth + 1);
      patch = reshape(trainX(mod(i-1,size(trainX,1))+1, :), CIFAR_DIM);
      patch = patch(r:r+PatchHeight-1,c:c+PatchWidth-1,:);
      patches(i,:) = patch(:)';
    end
    
    % normalize for contrast
    patches = bsxfun(@rdivide, bsxfun(@minus, patches, mean(patches,2)), sqrt(var(patches,[],2)+10));

    % whiten
    C = cov(patches);
    M = mean(patches);
    [V,D] = eig(C);
    P = V * diag(sqrt(1./(diag(D) + WhiteParam))) * V';
    patches = bsxfun(@minus, patches, M) * P;

    % run K-Means
    centroids = run_kmeans(patches, NumCentroids, KMeansIters);

    % get training features
    trainXC = extract_features2(trainX, centroids, PatchWidth, PatchHeight, CIFAR_DIM, ...
                                M,P);
    
    trainXC_mean = mean(trainXC);
    trainXC_sd = sqrt(var(trainXC)+ExtraNoise);
    trainXCs = bsxfun(@rdivide, bsxfun(@minus, trainXC, trainXC_mean), trainXC_sd);
    trainXCs = [trainXCs, ones(size(trainXCs,1),1)];

    theta = train_svm(trainXCs, trainY, SVMC);

    [val,labels] = max(trainXCs*theta, [], 2);
    fprintf('Train accuracy %f%%\n', 100 * (1 - sum(labels ~= trainY) / length(trainY)));

    testXC = extract_features2(testX, centroids, PatchWidth, PatchHeight, CIFAR_DIM, M,P);

    testXCs = bsxfun(@rdivide, bsxfun(@minus, testXC, trainXC_mean), trainXC_sd);
    testXCs = [testXCs, ones(size(testXCs,1),1)];

    [val,labels] = max(testXCs*theta, [], 2);

    acc = 100 * (1 - sum(labels ~= testY) / length(testY));
    
    fprintf('Validation accuracy %f%%\n', acc);
  end  
end