function kappa = get_kappa(X,G,N)
    P=perms(1:N);
    maxn=-inf;
    for i=1:size(P,1)
     n=0;
     for j=1:length(X)
      if G(j)==P(i,X(j))
       n=n+1;
      end
     end
     if n>maxn
      maxn=n;
      maxi=i;
     end
    end
    % Build matrix
    A=zeros(N,N);
    for j=1:length(X)
      x=P(maxi,X(j));
      g=G(j);
      A(x,g)=A(x,g)+1;
    end
    % Compute the kappa index
    t=0;
    for i=1:N
     t=t+sum(A(i,:))*sum(A(:,i));
    end
    kappa=(length(X)*trace(A)-t)/(length(X)*length(X)-t);
end
