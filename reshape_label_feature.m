function [d,c]=reshape_label_feature(D,TRIG,cl,MODE1)
% D 	data, each row is one time point
% TRIG	trigger time points
% Class class information
% class_times	classification times, combinations of times must be in one row 
% t_ref	reference time for Class 0 (optional)
% if ~isempty(t0)
% 	warning('arg5 (t_ref) should be empty. Use MODE.WIN=t_ref instead.') 
% end; 

CC = []; Q = [];tsd=[];md=[];
if isstruct(MODE1)
% 	CC.T = MODE1; 
	T  = MODE1.Segments;
	t0 = MODE1.WIN; 
else 
	T = MODE1; 	
end; 	 

tmp=cl;tmp(isnan(tmp))=0;
TRIG = TRIG(:);
tmp  = ~any(isnan(cl),2); 
TRIG = TRIG(tmp);
cl   = cl(tmp);

if size(cl,2)>1,
        cl2 = cl(:,2);          % 2nd column contains the group definition, ( Leave-One (Group) - Out ) 
        cl  = cl(:,1); 
else
        cl2 = [1:length(cl)]';  % each trial is a group (important for cross-validation); Trial-based LOOM  
end;
[CL,i,cl] = unique(cl);
CL2 = unique(cl2);
%[CL,iCL] = sort(CL);

% add sufficient NaNs at the beginning and the end 
tmp = min(TRIG)+min(min(T))-1;
if tmp<0,
        TRIG = TRIG - tmp;
        D = [repmat(nan,[-tmp,size(D,2)]);D];
end;        
tmp = max(TRIG)+max(max(T))-size(D,1);
if tmp>0,
        D = [D;repmat(nan,[tmp,size(D,2)])];
end;        


for k = 1:size(T,1),
        if t0(k),
                c = []; d = [];
                for k1 = 1:length(CL), 
                        t = perm(TRIG(cl==k1),T(k,:));
                        d = [d; D(t(:),:)];
                        c = [c; repmat(k1,prod(size(t)),1)];
                end;

        end;
end;
