function [terrs, crosste, errs, allterrors] = classbp2cg(w1, w_class, data, targets,...
    testdata, testtargets, numits, lambda)

  Dim = [size(data,2), size(w1,2), size(w_class,2), size(w_class,2)];
  allterrors = [];
  for i = 1:numits
      [x,fx] = minimize([w1(:); w_class(:)], 'classbp_grads', 3, Dim, data, targets, lambda);
      
      w1 = reshape(x(1:(Dim(1)+1)*Dim(2)), Dim(1)+1, Dim(2));
      w_class = reshape(x(((Dim(1)+1)*Dim(2))+1:end), Dim(2)+1, Dim(3));

      N = size(data,1);
      w1probs = 1./(1+exp(-[data, ones(N,1)]*w1));
      w1probs = [w1probs ones(N,1)];
      targetout = exp(w1probs*w_class);
      targetout = bsxfun(@rdivide, targetout, sum(targetout,2));
      crosste = -sum(sum( targets.*log(targetout)));
      [tmp, preds] = max(targetout,[],2);
      [tmp, corr] = max(targets,[],2);
      errs = sum(preds ~= corr);

      N = size(testdata,1);
      w1probs = 1./(1+exp(-[testdata, ones(N,1)]*w1));
      w1probs = [w1probs ones(N,1)];
      targetout = exp(w1probs*w_class);
      targetout = bsxfun(@rdivide, targetout, sum(targetout,2));
      [tmp, preds] = max(targetout,[],2);
      [tmp, corr] = max(testtargets,[],2);
      terrs = sum(preds ~= corr);
      allterrors = [allterrors; terrs];
      fprintf('err: %f, terr: %f\n', errs, terrs);
      if (size(allterrors,1) > 5)
        if (allterrors(end) - allterrors(end-2) == 0) && (allterrors(end) - allterrors(end-1) == 0)
          break
        end
      end
  end
