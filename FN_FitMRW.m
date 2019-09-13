%%   [GZM] Inducible Transcription Factors   %%
% ------------------------------------------- %
% FUNCTION: Perform MCMC parameter estimation %

% Created by Mariana G�mez-Schiavon
% August 2019

% FN_FitMRW : Find the set of parameters that best fit the data.
%
%   [] = FN_FitMRW(X,H,p,M,D,s,fp,ExID,printAll)
%   X : Vector (array) of TF concentration
%   H : Vector of inducer (hormone) concentration
%   M : Transcriptional model to consider
%       ('Mechanistic','HillxBasal','SimpleHill')
%   p : Structure with the kinetic parameters
%   D : Measured output (data) matrix [length(H) x length(X)]
%   s : Random number generator seed
%   f : Structure (array) with information to fit parameters
%    .par : Parameter to fit (e.g. 'mY')
%    .cov : Covariance to calculate parameter perturbations (e.g. 1e-3)
%    .lim : Range of acceptable values (e.g. [0,1])
%   I : Number of iterations
%   ExID : Code for output file name
%   printAll : Flag for printing full random walk
%
%   OUTPUT bestP : Array of the best set of parameters
%          minE  : Error of the best set of parameters
%
%   See also FN_SS_SimpleHill.m
%   See also FN_SS_HillxBasal.m
%   See also FN_SS_Mechanistic.m
%   See also FN_FitError.m

function [bestP,minE] = FN_FitMRW(X,H,p,M,D,s,f,I,ExID,printAll)
    mrw.s = s;
    mrw.f = f;
    mrw.P = zeros(I,length(f));     % OUTPUT: Parameters.
    mrw.e = zeros(I,1);             % OUTPUT: Error function values.
    Mstep = 2;

    % (1) Define random number generator:
    rng(s,'twister');
    r.tL = rand(I,1);               % To evaluate proposal acceptance.
    r.Pe = zeros(I,length(f));      % Parameter perturbations.
    for i = 1:length(f)
        r.Pe(:,i) = mvnrnd(zeros(I,1),f(i).cov);
        % (2) Initialize system:
        mrw.P(1,i) = 10.^((rand()*(log10(f(i).lim(2)) ...
                                    - log10(f(i).lim(1)))) ...
                                    + log10(f(i).lim(1)));
        p.(f(i).par) = mrw.P(1,i);
    end
    mrw.e(1)   = FN_FitError(X*p.nM,H,p,M,D*p.nM);

    % (3) Iterate:
    for j = 2:I
        mrw.P(j,:) = mrw.P(j-1,:);
        mrw.e(j)   = mrw.e(j-1,:);
        % Alternative parameter set:
        for i = 1:length(f)
            p.(f(i).par) = min(max(f(i).lim(1),mrw.P(j,i)*(Mstep^r.Pe(j,i))),f(i).lim(2));
        end
        % Generate proposal:
        myE = FN_FitError(X*p.nM,H,p,M,D*p.nM);
        % If proposal is accepted, update system:
        if(r.tL(j) < exp(mrw.e(j)-myE))
            for i = 1:length(f)
                mrw.P(j,i) = p.(f(i).par);
            end
            mrw.e(j) = myE;
        end
        % Save progress:
        if(printAll && (mod(j,10000)==0))
            j0 = j + 1
            save('TEMP_MRW.mat','mrw','j0','r','p');
        end
    end
    clear j i myE

    % (4) Save:
    if(printAll)
        save(cat(2,'MRW_',ExID,'_s',num2str(s),'.mat'),'mrw','p');
        delete('TEMP_MRW.mat');
    end
    [a b] = min(mrw.e);
    bestP = mrw.P(b,:);
    minE  = a;
    clear a b
end
