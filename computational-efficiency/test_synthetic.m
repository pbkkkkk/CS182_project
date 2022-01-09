
clearvars; clc;

%% Basic setting
n = 10000;      %%%  n = the number of nodes
K = 2;          %%% K = the number of blocks
m = n/K;        %%% m = the block size

%% ground truth 
Xt = kron(eye(K), ones(m)); Xt(Xt==0)=-1; %%% Xt = the true cluster matrix
xt = [ones(m,1); -ones(m,1)]; %%%  xt = the true cluster vector

%% generate an adjacency matrix A by Binary SBM
b = 16; a = (sqrt(b) + sqrt(2))^2 + 1;  %%%  choose the constants alpha, beta in p, q, resp.
p = a*log(n)/n;       %%%  p = the within-cluster connecting probability; 
q = b*log(n)/n;       %%%  q = the across-cluster connecting probability.       
Ans11 = rand(m); Al11 = tril(Ans11,-1); 
As11 = Al11 + Al11'+diag(diag(Ans11)); clear Ans11 Al11
A11 = double(As11<=p); A11 = sparse(A11); clear As11
As12 = rand(m);
A12 = double(As12<=q); A12 = sparse(A12); clear As12
Ans22 = rand(m); Al22 = tril(Ans22,-1); 
As22 = Al22 + Al22' + diag(diag(Ans22)); clear Ans22 Al22
A22 = double(As22<=p); A22 = sparse(A22); clear As22
A = ([A11,A12;A12',A22]); clear A11 A12 A22
A = sparse(A);

%% choose the running algorithm
run_PPM = 1; run_GPM = 1; run_MGD = 1; run_SDP = 0; run_SC = 1;

%% total running time
[ttime_PPM, ttime_GPM, ttime_MGD, ttime_SDP, ttime_SC] = deal(0);

for repeat = 1:10 
            
            fprintf('Repeat Num: %d \n', repeat);
            
            %% initial point generated by uniform distribution over the sphere
            Q = randn(n,2); Q0 = Q*(Q'*Q)^(-0.5);  
            
            %% choose the parameters for the running methods
            maxiter = 2e3; tol = 1e-3; report_interval = 1e3; total_time = 1e3; print = 1;
            
            %% PPM for MLE
            if run_PPM == 1
                    opts = struct('T', maxiter, 'tol', tol, 'report_interval', report_interval,...
                        'total_time', total_time, 'init_iter', 0.2, 'print', print);
                    tic; [x_PPM, iter_PPM, fval_collector_PPM] = PPM(A, Q0, opts); time_PPM=toc; 
                    ttime_PPM = ttime_PPM + time_PPM;
                    dist_PPM = norm(x_PPM*x_PPM'-Xt, 'fro');
            end
            
            %% GPM for Regularized MLE
            if run_GPM == 1
                    rho = sum(sum(A))/n^2;
                    opts = struct('T', maxiter, 'rho', rho, 'tol', tol, 'report_interval', report_interval,...
                        'total_time', total_time, 'init_iter', 0.2, 'print', print); 
                    tic; [x_GPM, iter_GPM, fval_collector_GPM] = GPM(A, Q0, opts); time_GPM=toc; 
                    ttime_GPM = ttime_GPM + time_GPM;
                    dist_GPM = norm(x_GPM*x_GPM'-Xt, 'fro');
            end
                         
            %% Manifold Gradient Descent
            if run_MGD == 1
                    rho = (p+q)/2;
                    opts = struct('rho', rho, 'T', maxiter, 'tol', tol, 'report_interval', report_interval,...
                        'total_time', total_time, 'print', print);             
                    tic; [Q, iter_MGD, fval_collector_MGD] = manifold_GD(A, Q0, opts); time_MGD=toc;
                    ttime_MGD = ttime_MGD + time_MGD;
                    dist_MGD =  norm(Q*Q'-Xt, 'fro');
            end
            
            %% ADMM for SDP
            if run_SDP == 1
                   opts = struct('rho', 0.2, 'T', maxiter, 'tol', tol, 'report_interval', report_interval,...
                       'total_time', 1800, 'quiet', print);
                   tic; [X_SDP, fval_collector_SDP] = sdp_admm1(A, Q0*Q0', 2, opts); time_SDP = toc;
                   ttime_SDP = ttime_SDP + time_SDP;
                   Xt(Xt == -1) = 0;
                   dist_SDP =  norm(X_SDP-Xt, 'fro');
            end
            
            %% Spectral Clustering
            if run_SC == 1
                    tic; x_SC = SC(A); time_SC = toc;
                    ttime_SC = ttime_SC + time_SC;
                    dist_SC =  min(norm(x_SC-xt), norm(x_SC+xt));
            end
                        
end 

time_PPM = ttime_PPM/10; time_GPM = ttime_GPM/10; time_SC = ttime_SC/10; 
time_SDP = ttime_SDP/10; time_MGD = ttime_MGD/10;

clear A;



