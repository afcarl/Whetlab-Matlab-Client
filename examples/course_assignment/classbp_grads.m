function [f, df] = classbp_grads(VV,Dim,XX,target, lambda)

l1 = Dim(1);
l2 = Dim(2);
l3= Dim(3);
l4 = size(target,2);
N = size(XX,1);

% Do decomversion.
w1 = reshape(VV(1:(l1+1)*l2),l1+1,l2);
xxx = (l1+1)*l2;

w_class = reshape(VV(xxx+1:end), size(w1,2)+1, size(target,2));%xxx+(l2+1)*l3),l2+1,l3);

XX = [XX ones(N,1)];
w1probs = 1./(1+exp(-XX*w1)); w1probs = [w1probs  ones(N,1)];
 
targetout = exp(w1probs*w_class);
targetout = targetout./repmat(sum(targetout,2),1,l4);  
f = -sum(sum( target.*log(targetout))) + 0.5*sum(sum(lambda.*w1.^2)) + 0.5*sum(sum(lambda.*w_class.^2));

IO = (targetout-target);
Ix_class=IO; 
dw_class =  w1probs'*Ix_class - lambda.*w_class;

Ix1 = (Ix_class*w_class').*w1probs.*(1-w1probs); 
Ix1 = Ix1(:,1:end-1);
dw1 =  XX'*Ix1 - lambda.*w1;

df = [dw1(:)' dw_class(:)']';