function surr = CBIG_RL2017_get_AR_surrogate(TC,n_surr,order,distribution)

% surr = CBIG_RL2017_get_AR_surrogate(TC,n_surr,order,distribution)
% This function generates autoregressive (AR) surrogates. The three
% mandatory inputs are:

% 'TC'                 original time course of size (num_timepoints,num_variables). 
%                      In this case num_variables is the numbers of ROIs.
% 'n_surr'             desired number of surrogate samples to be generated
% 'order'              order of the AR model used to generate surrogate data

% The option 'distribution' controls the way noise is generated to yield surrogates. 
% Possibilities are:

%   'gaussian'         noise computed from gaussian distribution
%                      matched to the covariance of residuals (default)
%   'nongaussian'      noise generated by permuting the residuals

% Output
% 'surr'               matrix of size (num_timepoints,num_variables,n_surr)
%                      containing surrogate datasets

% Written by Raphael Liegeois and CBIG under MIT license: https://github.com/ThomasYeoLab/CBIG/blob/master/LICENSE.md
% Contact: Raphael Liegeois (Raphael.Liegeois@gmail.com)

%%% Reference: R. Liegeois et al. (2017). Interpreting Temporal
%%% Fluctuations In Resting-State Functional Connectivity MRI, NeuroImage.


%% input check
if nargin < 3
    error('Not enough input arguments')
elseif nargin == 3
    distribution='gaussian';
elseif nargin > 4
    error('Too many input arguments')
end

%% Identify parameters
T  = size(TC,1);
k  = size(TC,2);
p  = order;

%% Remove zero lines in TS (they cause NaN in the AR model parameter)
TS = TC';
TS(sum(TS, 2)==0, :) = [];

%Identify AR model from whole dataset
[Y,B,Z,E] = CBIG_RL2017_ar_mls(TS',order);
w         = B(:,1);%constant term
A         = cell(1,order);
for i=1:order
    A{i}=B(:,k*(i-1)+2:k*i+1);
end

if strcmp(distribution,'gaussian')
    
    disp('Computing surrogates using a gaussian approach')
    
    E     = E'; %match matlab structure
    P     = mean(E);
    EC    = cov(E);
    E_cov = (mvnrnd(P,EC,size(E,1)))';
    surr  = zeros(T,k,n_surr);
    
    for u=1:n_surr
        perm           = randperm(T-p);
        AR_surr        = zeros(T,k);
        AR_surr(1:p,:) = (TS(:,perm(1):perm(1)+p-1))'; %Initialization of the AR surrogate with portion of original TC
        perm2          = randperm(T-p);
        
        for i=p+1:T %Completion of the AR surrogate
            AR_surr(i,:) = w;
            for j=1:p
                AR_surr(i,:) = AR_surr(i,:)+(A{j}*AR_surr(i-j,:)')';
            end
            AR_surr(i,:) = AR_surr(i,:)+E_cov(:,perm2(i-p))'; %Adding gaussian input noise
        end
        surr(:,:,u)=AR_surr;
    end
    
elseif strcmp(distribution,'nongaussian')
    
    disp('Computing surrogates using a nongaussian approach')
    
    for u=1:n_surr
        perm           = randperm(T-p);
        AR_surr        = zeros(T,k);
        AR_surr(1:p,:) = (TS(:,perm(1):perm(1)+p-1))'; %Initialization of the AR surrogate with portion of original TC
        perm2          = randperm(T-p);
        
        for i=p+1:T %Completion of the AR surrogate
            AR_surr(i,:)=w;
            for j=1:p
                AR_surr(i,:) = AR_surr(i,:)+(A{j}*AR_surr(i-j,:)')';
            end
            AR_surr(i,:) = AR_surr(i,:)+E(:,perm2(i-p))';
        end
        surr(:,:,u) = AR_surr;
    end
else
    error('Unknown distribution: distribution should be either ''gaussian'' or ''nongaussian''')
end


